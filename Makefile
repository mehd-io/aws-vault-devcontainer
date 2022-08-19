test:
	aws-vault exec $(AWS_PROFILE) -- aws s3 ls

