version: 0.2
phases:
  install:
    runtime-versions:
      docker: 18
    commands:
      - rm -rf *
      - git config --global credential.helper '!aws codecommit credential-helper $@'
      - git config --global credential.UseHttpPath true
      - git config --global user.email ""
      - git config --global user.name "AWS K8S Common Pipeline"
      - git clone https://git-codecommit.${region}.amazonaws.com/v1/repos/devops
      - git clone --branch ${k8s_deploy_branch} https://git-codecommit.${region}.amazonaws.com/v1/repos/k8s-deploy
      - HELM_C1="repo add fmontezuma-${helm_repo_env} https://fmontezuma.github.io/helm-chart/${helm_repo_env}/"
      - HELM_C2="helm fetch fmontezuma-${helm_repo_env}/k8s-common --untar"
      - HELM_C3="helm template ./k8s-common --output-dir ./k8s-deploy/"
      - HELM_CMD="$${HELM_C1} && $${HELM_C2} && $${HELM_C3}"
  build:
    commands:
      - rm -rf ./k8s-deploy/k8s-common
      - docker run --rm -v $(pwd):/apps -v ~/.kube/config:/root/.kube/config alpine/helm:2.9.0 $HELM_CMD
      - cd k8s-deploy
      - git add --all
      - git commit -m "K8S-COMMON - $${CODEBUILD_RESOLVED_SOURCE_VERSION}"
      - git push origin $BRANCH
