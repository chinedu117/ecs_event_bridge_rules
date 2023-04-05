variable "informant_sns_topic_arn" {
    type = string
    description = "SNS topic"
}

variable "service_name" {
    type = string
    description = "ECS ervice name"
}

variable "service_arn" {
    type = string 
    description = "Service arn"
}

variable "environment" {
    type = string
    description = "Environment"
}
