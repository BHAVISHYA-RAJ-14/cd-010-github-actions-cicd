import jwt
import datetime
import os

def generate_token():
    # Use the current project repository
    repo = "BHAVISHYA-RAJ-14/cd-010-github-actions-cicd"
    
    payload = {
        'sub': f'repo:{repo}:ref:refs/heads/main',
        'aud': 'sts.amazonaws.com',
        'iat': datetime.datetime.utcnow(),
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1)
    }
    # This is for demo purposes only; in production, GitHub signs these tokens.
    token = jwt.encode(payload, 'demo-secret-not-for-prod', algorithm='HS256')
    print(f"Generated Demo OIDC Token for {repo}:")
    print(token)

if __name__ == "__main__":
    generate_token()
