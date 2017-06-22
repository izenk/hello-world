pipeline {
    agent { label 'docker-compose' }

    stages {
        stage('Build') {
            steps {
                git url: "https://github.com/izenk/hello-world.git", branch: 'zii'
                echo 'Building..'
                sh ('docker-compose build --force-rm')
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
                sh ('docker-compose up -d')
                sh ('curl -sSvk http://localhost:8080 | grep "world"')
            }
        }
    }
}
