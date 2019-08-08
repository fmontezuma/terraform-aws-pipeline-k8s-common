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
      - git clone https://git-codecommit.${region}.amazonaws.com/v1/repos/${project_name}-devops
      - git clone https://git-codecommit.${region}.amazonaws.com/v1/repos/${project_name}-k8s-deploy
      - cd ${project_name}-k8s-deploy
      - git checkout ${k8s_deploy_branch} 2>/dev/null || git checkout -b ${k8s_deploy_branch} 
      - cd ..
      - echo "helm init --client-only" >> helmscript.sh
      - echo "helm repo add fmontezuma-${helm_repo_env} https://fmontezuma.github.io/helm-chart/${helm_repo_env}/" >> helmscript.sh
      - echo "helm fetch fmontezuma-${helm_repo_env}/k8s-common --untar" >> helmscript.sh
      - echo "helm template ./k8s-common --values=./${project_name}-devops/helm/values/k8s-common/${k8s_deploy_branch}.yml --output-dir ./${project_name}-k8s-deploy/" >> helmscript.sh
  build:
    commands:
      - rm -rf ./${project_name}-k8s-deploy/k8s-common
      - docker run --rm -v $(pwd):/apps --entrypoint=/bin/sh alpine/helm:2.9.0 helmscript.sh
      - rm helmscript.sh
      - cd ${project_name}-k8s-deploy
      - git add --all
      - git commit --allow-empty -m "K8S-COMMON - $${CODEBUILD_RESOLVED_SOURCE_VERSION}"
      - git push origin ${k8s_deploy_branch}
