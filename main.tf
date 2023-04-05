
locals {
    service_name = var.service_name
    service_arn = var.service_arn
    environment = var.environment
    informant_sns_topic_arn = var.informant_sns_topic_arn

    deployment_failed = {
      subject = "ECS TASK: \"<event_name>\""
      body = "ECS task <resource_arn> deployment failed. The reason for failure : <reason> , time: <time_occured> , Event Name: <event_name>"
      remedy = "Log on to AWS to see the check the possible cause of the failure."
      severity = "WARN"
      channels = "slack"
    }

    deployment_rollback = {
      subject = "ECS TASK: ROLLBACK STARTED"
      body = "ECS task <resource_arn> is being rolled back to the previous version, time: <time_occured> , Event Name: <event_name>"
      remedy = "Log on to AWS to see the check the possible cause of the failure."
      severity = "WARN"
      channels = "slack"
    }

    deployment_success = {
      subject = "ECS TASK: <event_name>"
      body = "ECS task <resource_arn> deployed successfully, time: <time_occured> , Event Name: <event_name>"
      remedy = "No action needed"
      severity = "INFO"
      channels = "slack"
    }

    deployment_inprogress = {
      subject = "ECS TASK: <event_name>"
      body = "ECS task <resource_arn> is being rolled back to the previous version, time: <time_occured> , Event Name: <event_name>"
      remedy = "Log on to AWS to see the check the possible cause of the failure."
      severity = "WARN"
      channels = "slack"
    }

}

resource "aws_cloudwatch_event_rule" "deployment_successfull" {
   name        = "task-${local.service_name}-${local.environment}-deployment-success"
   description = "Task successfully deployed"
   event_pattern = jsonencode({
     source = ["aws.ecs"]
     detail-type = ["ECS Deployment State Change"]
     detail =  {
                 eventType = ["INFO"]
                 eventName = ["SERVICE_DEPLOYMENT_COMPLETED"]
                 }
     resources = [ local.service_arn ]
   })
 }

 resource "aws_cloudwatch_event_target" "sns_success" {
   rule      = aws_cloudwatch_event_rule.deployment_successfull.name
   target_id = "task-${local.service_name}-${local.environment}-deployment-success.target"
   arn       = local.informant_sns_topic_arn

   input_transformer {
     input_paths = {
       resource_arn= "$.resources[0]"
       time_occured = "$.detail.updatedAt" 
       deployment_id = "$.detail.deploymentId"
       event_name = "$.detail.eventName"
       reason = "$.detail.reason"
     }
     # Here we configure the json body that would be sent to SNS  

     input_template = replace(replace(jsonencode(local.deployment_success),"\\u003e", ">"),"\\u003c","<")
   }
 }


resource "aws_cloudwatch_event_rule" "deployment_rollback" {
   name        = "task-${local.service_name}-${local.environment}-deployment-rollback"
   description = "Task deployment rollback"
   event_pattern = jsonencode({
     source = ["aws.ecs"]
     detail-type = ["ECS Deployment State Change"]
     detail =  {
                 eventType = ["INFO"]
                 eventName = ["SERVICE_DEPLOYMENT_IN_PROGRESS"]
                 }
     reason = [{ prefix = "ECS deployment circuit breaker: rolling back to deploymentId" }]
     resources = [ local.service_arn ]
   })
 }

  resource "aws_cloudwatch_event_target" "sns_rollback" {
   rule      = aws_cloudwatch_event_rule.deployment_rollback.name
   target_id = "task-${local.service_name}-${local.environment}-deployment-rollback.target"
   arn       = local.informant_sns_topic_arn

   input_transformer {
     input_paths = {
       resource_arn= "$.resources[0]"
       time_occured = "$.detail.updatedAt" 
       deployment_id = "$.detail.deploymentId"
       event_name = "$.detail.eventName"
       reason = "$.detail.reason"
     }
     # Here we configure the json body that would be sent to SNS  

     input_template = replace(replace(jsonencode(local.deployment_rollback),"\\u003e", ">"),"\\u003c","<")
   }
 }


resource "aws_cloudwatch_event_rule" "deployment_progress" {
   name        = "task-${local.service_name}-${local.environment}-deployment-progress"
   description = "Task deployment progress"
   event_pattern = jsonencode({
     source = ["aws.ecs"]
     detail-type = ["ECS Deployment State Change"]
     detail =  {
                 eventType = ["INFO"]
                 eventName = ["SERVICE_DEPLOYMENT_IN_PROGRESS"]
                 }
     reason = [{ suffix = "in progress." }]
     resources = [ local.service_arn ]
   })
 }

  resource "aws_cloudwatch_event_target" "sns_progress" {
   rule      = aws_cloudwatch_event_rule.deployment_progress.name
   target_id = "task-${local.service_name}-${local.environment}-deployment-progress.target"
   arn       = local.informant_sns_topic_arn

   input_transformer {
     input_paths = {
       resource_arn= "$.resources[0]"
       time_occured = "$.detail.updatedAt" 
       deployment_id = "$.detail.deploymentId"
       event_name = "$.detail.eventName"
       reason = "$.detail.reason"
     }
     # Here we configure the json body that would be sent to SNS  

     input_template = replace(replace(jsonencode(local.deployment_inprogress),"\\u003e", ">"),"\\u003c","<")
   }
 }




resource "aws_cloudwatch_event_rule" "deployment_failed" {
   name        = "task-${local.service_name}-${local.environment}-deployment-failed"
   description = "Task deployment failed"
   event_pattern = jsonencode({
     source = ["aws.ecs"]
     detail-type = ["ECS Deployment State Change"]
     detail =  {
                 eventType = ["ERROR"]
                 eventName = ["SERVICE_DEPLOYMENT_FAILED"]
                 }
     resources = [ local.service_arn ]
   })
 }

  resource "aws_cloudwatch_event_target" "sns_rolback" {
   rule      = aws_cloudwatch_event_rule.deployment_failed.name
   target_id = "task-${local.service_name}-${local.environment}-deployment-failed.target"
   arn       = local.informant_sns_topic_arn

   input_transformer {
     input_paths = {
       resource_arn= "$.resources[0]"
       time_occured = "$.detail.updatedAt" 
       deployment_id = "$.detail.deploymentId"
       event_name = "$.detail.eventName"
       reason = "$.detail.reason"
     }
     # Here we configure the json body that would be sent to SNS  

     input_template = replace(replace(jsonencode(local.deployment_failed),"\\u003e", ">"),"\\u003c","<")
   }
 }