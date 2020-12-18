resource "aws_iam_role" "new_role" {
  name = var.role_name

  assume_role_policy = var.assume_policy
}

resource "aws_iam_role_policy" "new_policy" {
  name = var.role_name
  role = aws_iam_role.new_role.id

  policy = var.role_policy
}