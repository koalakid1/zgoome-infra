# Scripts

## create-sealed-secret.sh

Sealed Secret 생성을 자동화하는 스크립트입니다.

### 사용법

```bash
./scripts/create-sealed-secret.sh
```

### 실행 순서

1. **Secret 이름 입력** (예: `postgres-secret`)
2. **Namespace 입력** (예: `movie`, `db`)
3. **Scope 선택**
   - `1` - namespace-wide (추천)
   - `2` - strict
   - `3` - cluster-wide
4. **Secret 데이터 입력** (key=value 형식, 빈 줄로 종료)
   ```
   DB_USER=postgres
   DB_PASSWORD=mypassword
   DB_NAME=mydb

   ```
5. **Git commit 여부 선택**
6. **Git push 여부 선택**

### 예시

```bash
$ ./scripts/create-sealed-secret.sh

=== Sealed Secret Generator ===

Enter secret name (e.g., postgres-secret): test-secret
Enter namespace (e.g., movie, db): movie

Select scope:
  1) namespace-wide (recommended)
  2) strict
  3) cluster-wide
Enter choice [1-3] (default: 1): 1

Enter secret data (key=value format, empty line to finish):
  USERNAME=admin
    ✓ Added: USERNAME
  PASSWORD=secret123
    ✓ Added: PASSWORD

Generating sealed secret...
✓ Sealed secret created: /root/koalakid1/zgoome-infra/manifests/secrets/sealed-test-secret-movie.yaml

=== Summary ===
  Secret name: test-secret
  Namespace: movie
  Scope: namespace-wide
  Keys: USERNAME PASSWORD
  Output: /root/koalakid1/zgoome-infra/manifests/secrets/sealed-test-secret-movie.yaml

Do you want to commit and push? [y/N]: y
Enter commit message (default: Add sealed secret test-secret for movie):
Push to remote? [y/N]: y
✓ Changes pushed to remote

Done!
```

### 출력 파일

- 생성 위치: `manifests/secrets/`
- 파일명 규칙: `sealed-{SECRET_NAME}-{NAMESPACE}.yaml`

### 요구사항

- `kubeseal` 설치 필수
- Sealed Secrets Controller가 kube-system 네임스페이스에 실행 중이어야 함
- KUBECONFIG 환경변수 설정 (기본값: `/etc/rancher/k3s/k3s.yaml`)
