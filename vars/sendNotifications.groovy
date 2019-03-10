#!/usr/bin/env groovy

/**
 * Send notifications based on build status string
 */
def call(String buildStatus, String channelName) {

  // Default values
  def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
  def summary = "${subject} (${env.BUILD_URL})"
  def details = """Build Failed ${env.JOB_NAME} [${env.BUILD_NUMBER}]
                Check console output at (<${env.BUILD_URL}|Open>) ${env.JOB_NAME} [${env.BUILD_NUMBER}];
                """
  def message = """Build Notification
                  - STATUS: *${buildStatus}*
                  - BRANCH: *${env.GERRIT_BRANCH}*
                  - PROJECT: *${env.PROJECT}*
                  - (<${env.BUILD_URL}|Open>)"
                """

  // Override default values based on build status
  if (buildStatus == 'STARTED') {
    color = 'YELLOW'
    colorCode = '#FFFF00'
  } else if (buildStatus == 'SUCCESS') {
    color = 'GREEN'
    colorCode = '#00FF00'
  } else {
    color = 'RED'
    colorCode = '#FF0000'
  }

  // Send notifications
  //slackSend (color: colorCode, channel: channelName, message: summary)

  //rocketChat notification
  rocketSend (color: colorCode, channel: channelName, message: message)

  //email notification
  emailext (
      to: '',
      subject: subject,
      body: details,
      attachLog: 'true',
      compressLog: 'true',
      attachmentsPattern: '**/*.log',
      recipientProviders: [requestor()]
  )
}