resource "aws_iam_role" "jenkins" {
  count = var.create_iam_instance_profile ? 1 : 0
  name  = "${var.name_prefix}-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.create_iam_instance_profile ? 1 : 0
  role       = aws_iam_role.jenkins[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins" {
  count = var.create_iam_instance_profile ? 1 : 0
  name  = "${var.name_prefix}-ec2"
  role  = aws_iam_role.jenkins[0].name
  tags  = var.tags
}
