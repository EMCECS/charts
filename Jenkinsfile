import com.emc.pipelines.artifactory.*

pipeline {
    agent {
            label 'sc_ci_devkit && location_us'
        }

    environment {
        PWD = pwd()
        DOCKER_IMAGE = 'asdrepo.isus.emc.com:8085/emcecs/fabric/devkit:latest'
        CONTAINER_PATH = '/charts'
        DOCKER_ARGS = '-e "EUID=0" -e "EGID=0" -e "USER_NAME=root" -e "STDOUT=true" -e "JENKINS_RUN=true"  -w $CONTAINER_PATH -v $PWD:$CONTAINER_PATH:rw,z'
        GH_CREDS = ''
    }

    options {
        timeout(time: 60, unit: 'MINUTES')
    }

    stages {
        stage('Make') {
            steps {
                script {
                    loader.loadFrom('pipelines': [common: 'common',
                                                  github: 'github',
                                                  git_operations: 'infra/git_operations',],)
                    GH_CREDS = common.PUBLIC_GITHUB_RW_CRED_ID;
                    github.postStatus('ssh://git@github.com:22/EMCECS/charts.git',
                                         "$GIT_COMMIT",
                                         [state: github.COMMIT_BUILD_STATUSES.IN_PROGRESS])
                    success = false
                }

                withDockerContainer(image: DOCKER_IMAGE, args: DOCKER_ARGS) {
                    sshagent([GH_CREDS]) {
                       sh('''
                            make dep
                            PATH=/tmp:$PATH
                            make update-dependencies
                            make test
                       ''')
                    }
                }
            }
        }
        stage('Publish') {
            steps {
                script {
                    loader.loadFrom('pipelines': [
                        artifactory : 'infra/artifactory',
                        common: 'common',
                        ])

                    success = true
                }
            }
        }
    }

    post {
        always {
            deleteDir()
            script {
                status = success ? github.COMMIT_BUILD_STATUSES.SUCCESSFUL : github.COMMIT_BUILD_STATUSES.FAILED;
                github.postStatus('ssh://git@github.com:22/EMCECS/charts.git', "$GIT_COMMIT", [
                    state: status,
                    description: status,
                ])
            }
        }
    }
}
