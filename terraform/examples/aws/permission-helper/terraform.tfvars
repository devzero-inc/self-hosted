################################################################################
# AWS account and cluster information
################################################################################
AWS_REGION   = "*"
ACCOUNT_ID   = "AWS_ACCOUNT_ID"
CLUSTER_NAME = "permissions-test"

################################################################################
# Condition resources and requests for policies
################################################################################
condition_resources = {}
condition_requests = {}

# Uncomment these to use a more strict policy
# condition_resources = {
#   Condition = {
#     StringEquals = {
#       "aws:ResourceTag/CreatedBy" : "DevZero"
#     }
#   }
# }
# condition_requests = {
#   Condition = {
#     StringEquals = {
#       "aws:RequestTag/CreatedBy" : "DevZero"
#     }
#   }
# }


################################################################################
# Module configuration
################################################################################
create_local_files = true
create_aws_user = false