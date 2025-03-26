prefix     = "garvit"
vpc_name   = "test"
project_id = "devzero-kubernetes-sandbox"
region     = "us-central1"

subnets = [
  {
    name          = "subnet-1"
    region        = "us-central1" 
    ip_cidr_range = "10.1.0.0/24"
    secondary_ip_range = [
      {
        range_name    = "subnet-1-secondary"
        ip_cidr_range = "192.168.1.0/24"
      }
    ]
  },
  {
    name          = "subnet-2"
    region        = "us-central1"  
    ip_cidr_range = "10.2.0.0/24"
    secondary_ip_range = [
      {
        range_name    = "subnet-2-secondary"
        ip_cidr_range = "192.168.2.0/24"
      }
    ]
  }
]
