/*
 * ============================================================
 * FLUTTER WEB CI/CD
 *
 * GitHub
 *   ↓
 * Flutter Clean
 *   ↓
 * Flutter Pub Get
 *   ↓
 * Flutter Analyze
 *   ↓
 * Flutter Test
 *   ↓
 * SonarQube
 *   ↓
 * Quality Gate
 *   ↓
 * Version SNAPSHOT / RELEASE
 *   ↓
 * Flutter Web Build
 *   ↓
 * Docker Build
 *   ↓
 * Nexus Docker Hosted
 *   ↓
 * K3s Rolling Deployment
 *   ↓
 * Verify
 *   ↓
 * Rollback
 *
 * Repository:
 * https://github.com/taqin21in/frontend-flutter.git
 * ============================================================
 */


// ============================================================
// GITHUB
// ============================================================

def gitRepo   = 'https://github.com/taqin21in/frontend-flutter.git'
def gitBranch = 'main'


// ============================================================
// TOOLS
// ============================================================

def flutterHome = '/opt/flutter'

def sonarScannerHome = '/opt/sonar-scanner'


// ============================================================
// SONARQUBE
// ============================================================

def sonarProjectKey  = 'frontend-flutter'
def sonarProjectName = 'frontend-flutter'


// ============================================================
// NEXUS
// ============================================================

def nexusRegistry = '192.168.0.103:8082'

def dockerImageName =
    "${nexusRegistry}/docker-hosted/flutter-web"


// ============================================================
// K3S
// ============================================================

def k3sNamespace  = 'frontend'
def k3sDeployment = 'flutter-web'
def k3sContainer  = 'flutter-web'

def k3sKubeconfig =
    '/home/jenkins/k3s-jenkins.yaml'


// ============================================================
// VARIABLES
// ============================================================

def dockerImage
def appVersion
def buildType

def deploymentStarted = false


// ============================================================
// JENKINS
// ============================================================

node('runner') {

    properties([

        disableConcurrentBuilds(),

        buildDiscarder(
            logRotator(
                numToKeepStr: '20'
            )
        ),

        parameters([

            choice(
                name: 'BUILD_TYPE',

                choices: [
                    'SNAPSHOT',
                    'RELEASE'
                ],

                description:
                    'Pilih SNAPSHOT untuk development atau RELEASE untuk production.'
            )
        ])
    ])


    try {

        // ====================================================
        // 01 - CHECKOUT
        // ====================================================

        stage('Checkout') {

            deleteDir()

            git(
                url: gitRepo,
                branch: gitBranch,
                credentialsId: 'github-credential'
            )

            echo "Git checkout completed."
        }


        // ====================================================
        // 02 - ENVIRONMENT CHECK
        // ====================================================

        stage('Environment Check') {

            sh '''
                set -e

                echo "========================================"
                echo "Environment Check"
                echo "========================================"


                echo ""
                echo "Flutter:"
                /opt/flutter/bin/flutter --version


                echo ""
                echo "SonarScanner:"
                /opt/sonar-scanner/bin/sonar-scanner --version


                echo ""
                echo "Docker:"
                docker --version


                echo ""
                echo "Kubectl:"
                kubectl version --client
            '''
        }


        // ====================================================
        // 03 - FLUTTER CLEAN
        // ====================================================

        stage('Flutter Clean') {

            sh '''
                set -e

                /opt/flutter/bin/flutter clean
            '''
        }


        // ====================================================
        // 04 - FLUTTER PUB GET
        // ====================================================

        stage('Flutter Pub Get') {

            sh '''
                set -e

                /opt/flutter/bin/flutter pub get
            '''
        }


        // ====================================================
        // 05 - FLUTTER ANALYZE
        // ====================================================

        stage('Flutter Analyze') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Analyze"
                echo "========================================"

                /opt/flutter/bin/flutter analyze
            '''
        }


        // ====================================================
        // 06 - FLUTTER TEST
        // ====================================================

        stage('Flutter Test') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Test"
                echo "========================================"

                /opt/flutter/bin/flutter test
            '''
        }


        // ====================================================
        // 07 - SONARQUBE
        // ====================================================

        stage('SonarQube Analysis') {

            withSonarQubeEnv('SonarQube') {

                sh '''
                    set -e

                    echo "========================================"
                    echo "SonarQube Analysis"
                    echo "========================================"


                    /opt/sonar-scanner/bin/sonar-scanner \
                        -Dsonar.projectKey=frontend-flutter \
                        -Dsonar.projectName=frontend-flutter \
                        -Dsonar.sources=lib \
                        -Dsonar.tests=test \
                        -Dsonar.sourceEncoding=UTF-8
                '''
            }
        }


        // ====================================================
        // 08 - QUALITY GATE
        // ====================================================

        stage('Quality Gate') {

            timeout(
                time: 10,
                unit: 'MINUTES'
            ) {

                def result =
                    waitForQualityGate(
                        abortPipeline: true
                    )


                if (result.status != 'OK') {

                    error(
                        "Quality Gate FAILED: ${result.status}"
                    )
                }


                echo "Quality Gate PASSED."
            }
        }


        // ====================================================
        // 09 - VERSION
        // ====================================================

        stage('Version') {

            buildType =
                params.BUILD_TYPE


            def flutterVersion = sh(

                script: '''
                    grep '^version:' pubspec.yaml |
                    head -1 |
                    awk '{print $2}'
                ''',

                returnStdout: true

            ).trim()


            if (!flutterVersion) {

                error(
                    'Version tidak ditemukan di pubspec.yaml'
                )
            }


            /*
             * Contoh pubspec:
             *
             * version: 1.0.0+1
             *
             * Ambil:
             *
             * 1.0.0
             */

            def baseVersion =
                flutterVersion
                    .split('\\+')[0]


            // =================================================
            // SNAPSHOT
            // =================================================

            if (buildType == 'SNAPSHOT') {

                appVersion =
                    "${baseVersion}-SNAPSHOT"

                dockerImage =
                    "${dockerImageName}:${baseVersion}-SNAPSHOT-build-${env.BUILD_NUMBER}"


                echo """
                ========================================
                SNAPSHOT BUILD
                ========================================

                Flutter Version:
                ${flutterVersion}

                Application Version:
                ${appVersion}

                Docker Image:
                ${dockerImage}

                Jenkins Build:
                ${env.BUILD_NUMBER}

                ========================================
                """
            }


            // =================================================
            // RELEASE
            // =================================================

            else {

                appVersion =
                    getNextReleaseVersion(
                        nexusRegistry,
                        dockerImageName,
                        baseVersion
                    )


                dockerImage =
                    "${dockerImageName}:${appVersion}"


                echo """
                ========================================
                RELEASE BUILD
                ========================================

                Flutter Version:
                ${flutterVersion}

                Previous Version:
                ${baseVersion}

                Release Version:
                ${appVersion}

                Docker Image:
                ${dockerImage}

                ========================================
                """
            }
        }


        // ====================================================
        // 10 - FLUTTER WEB PREPARE
        // ====================================================

        stage('Flutter Web Prepare') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Web Prepare"
                echo "========================================"


                if [ ! -d "web" ]; then

                    echo "Flutter Web belum dikonfigurasi."

                    /opt/flutter/bin/flutter create . \
                        --platforms web

                else

                    echo "Flutter Web sudah tersedia."

                fi


                ls -lah web/
            '''
        }


        // ====================================================
        // 11 - FLUTTER WEB BUILD
        // ====================================================

        stage('Flutter Web Build') {

            sh '''
                set -e

                echo "========================================"
                echo "Flutter Web Build"
                echo "========================================"

                /opt/flutter/bin/flutter build web --release


                echo ""
                echo "Build output:"

                ls -lah build/web
            '''
        }


        // ====================================================
        // 12 - DOCKER BUILD & PUSH
        // ====================================================

        stage('Docker Build & Push') {

            withCredentials([

                usernamePassword(

                    credentialsId:
                        'nexus-credential',

                    usernameVariable:
                        'NEXUS_USERNAME',

                    passwordVariable:
                        'NEXUS_PASSWORD'
                )

            ]) {

                withEnv([

                    "DOCKER_IMAGE=${dockerImage}",

                    "DOCKER_REGISTRY=${nexusRegistry}"

                ]) {

                    sh '''
                        set -e

                        echo "========================================"
                        echo "Docker Login"
                        echo "========================================"


                        echo "$NEXUS_PASSWORD" |
                            docker login "$DOCKER_REGISTRY" \
                            --username "$NEXUS_USERNAME" \
                            --password-stdin


                        echo ""
                        echo "Docker Build:"


                        docker build \
                            --pull \
                            -t "$DOCKER_IMAGE" \
                            .


                        echo ""
                        echo "Docker Push:"


                        docker push "$DOCKER_IMAGE"


                        echo ""
                        echo "Image pushed:"
                        echo "$DOCKER_IMAGE"
                    '''
                }
            }
        }


        // ====================================================
        // 13 - DEPLOY K3S
        // ====================================================

        stage('Deploy K3s') {

            deploymentStarted = true


            withEnv([

                "KUBECONFIG=${k3sKubeconfig}",

                "NAMESPACE=${k3sNamespace}",

                "DEPLOYMENT=${k3sDeployment}",

                "CONTAINER=${k3sContainer}",

                "DOCKER_IMAGE=${dockerImage}"

            ]) {

                sh '''
                    set -e

                    echo "========================================"
                    echo "K3s Deployment"
                    echo "========================================"


                    echo "Namespace : $NAMESPACE"
                    echo "Deployment: $DEPLOYMENT"
                    echo "Container : $CONTAINER"
                    echo "Image     : $DOCKER_IMAGE"


                    kubectl set image \
                        deployment/"$DEPLOYMENT" \
                        "$CONTAINER=$DOCKER_IMAGE" \
                        -n "$NAMESPACE"


                    kubectl rollout status \
                        deployment/"$DEPLOYMENT" \
                        -n "$NAMESPACE" \
                        --timeout=5m
                '''
            }
        }


        // ====================================================
        // 14 - VERIFY
        // ====================================================

        stage('Verify') {

            withEnv([

                "KUBECONFIG=${k3sKubeconfig}",

                "NAMESPACE=${k3sNamespace}",

                "DEPLOYMENT=${k3sDeployment}"

            ]) {

                sh '''
                    set -e

                    echo "========================================"
                    echo "K3s Verification"
                    echo "========================================"


                    kubectl get deployment \
                        "$DEPLOYMENT" \
                        -n "$NAMESPACE"


                    echo ""

                    kubectl get pods \
                        -n "$NAMESPACE" \
                        -o wide


                    echo ""

                    kubectl get service \
                        -n "$NAMESPACE"


                    echo ""

                    kubectl get ingress \
                        -n "$NAMESPACE" \
                        || true
                '''
            }
        }


        // ====================================================
        // SUCCESS
        // ====================================================

        echo """

        ========================================
        PIPELINE SUCCESS
        ========================================

        Application:
        Flutter Web

        Build Type:
        ${buildType}

        Application Version:
        ${appVersion}

        Docker Image:
        ${dockerImage}

        Nexus:
        ${nexusRegistry}

        K3s:
        ${k3sNamespace}/${k3sDeployment}

        Jenkins Build:
        ${env.BUILD_NUMBER}

        ========================================
        """


    } catch (Exception e) {

        echo "PIPELINE FAILED: ${e}"


        // ====================================================
        // ROLLBACK
        // ====================================================

        if (deploymentStarted) {

            try {

                withEnv([

                    "KUBECONFIG=${k3sKubeconfig}",

                    "NAMESPACE=${k3sNamespace}",

                    "DEPLOYMENT=${k3sDeployment}"

                ]) {

                    sh '''
                        echo "========================================"
                        echo "ROLLBACK"
                        echo "========================================"


                        kubectl rollout undo \
                            deployment/"$DEPLOYMENT" \
                            -n "$NAMESPACE"


                        kubectl rollout status \
                            deployment/"$DEPLOYMENT" \
                            -n "$NAMESPACE" \
                            --timeout=5m


                        echo "Rollback completed."
                    '''
                }

            } catch (Exception rollbackError) {

                echo "Rollback FAILED: ${rollbackError}"
            }
        }


        throw e


    } finally {


        // ====================================================
        // DOCKER CLEANUP
        // ====================================================

        if (dockerImage) {

            sh """
                docker image rm \
                    '${dockerImage}' || true
            """
        }


        // ====================================================
        // NEXUS LOGOUT
        // ====================================================

        sh """
            docker logout \
                '${nexusRegistry}' || true
        """


        // ====================================================
        // WORKSPACE CLEANUP
        // ====================================================

        deleteDir()
    }
}


// ============================================================
// GET NEXT RELEASE VERSION
// ============================================================

def getNextReleaseVersion(
    nexusRegistry,
    dockerImageName,
    baseVersion
) {

    def repository =
        "http://${nexusRegistry}/v2/docker-hosted/flutter-web/tags/list"


    withCredentials([

        usernamePassword(

            credentialsId:
                'nexus-credential',

            usernameVariable:
                'NEXUS_USERNAME',

            passwordVariable:
                'NEXUS_PASSWORD'
        )

    ]) {

        def tags = sh(

            script: """

                curl -fsS \
                    -u "\$NEXUS_USERNAME:\$NEXUS_PASSWORD" \
                    "${repository}" \
                    2>/dev/null \
                    || echo '{}'

            """,

            returnStdout: true

        ).trim()


        def versions = []


        /*
         * Cari Docker release:
         *
         * 1.0.0
         * 1.0.1
         * 1.0.2
         *
         * Tidak mengambil:
         *
         * 1.0.0-SNAPSHOT-build-1
         */

        def matcher =
            tags =~ /"([0-9]+\.[0-9]+\.[0-9]+)"/


        matcher.each {

            def version =
                it[1]


            if (
                version ==~ /^\d+\.\d+\.\d+$/
            ) {

                versions << version
            }
        }


        if (versions.isEmpty()) {

            return baseVersion
        }


        def maxVersion =
            versions.max { a, b ->

                def pa =
                    a.tokenize('.').collect {
                        it as Integer
                    }


                def pb =
                    b.tokenize('.').collect {
                        it as Integer
                    }


                pa <=> pb
            }


        def parts =
            maxVersion.tokenize('.').collect {
                it as Integer
            }


        /*
         * Jika:
         *
         * 1.0.0
         *
         * maka:
         *
         * 1.0.1
         */

        return "${parts[0]}.${parts[1]}.${parts[2] + 1}"
    }
}