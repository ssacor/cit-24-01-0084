# Lab 6 — Kubernetes Fundamentals with Minikube

This lab takes the same multi-container idea from Assignment 1 (Docker) and
moves it into **Kubernetes**. Instead of running containers with `docker run`,
we describe our app in **YAML files** and let **Kubernetes** run and manage it.

The app is the same "Frontend → API → Cache → Database" architecture:
- Frontend (nginx) — the web page
- API (httpbin) — a test REST API
- Cache (redis) — in-memory storage
- Database (postgres) — persistent storage with a StatefulSet

No custom code is needed — every image comes from Docker Hub.

---

## 1. What this project contains

```
lab6/
├── k8s/                          # all YAML manifests
│   ├── pod-frontend.yaml         # Part 2: single demo Pod
│   ├── deployment-frontend.yaml  # Part 3: self-healing Deployment
│   ├── service-frontend.yaml     # Part 5: NodePort Service
│   ├── api-deployment.yaml       # Part 7: API tier
│   ├── api-service.yaml          # Part 7: API Service
│   ├── cache-deployment.yaml     # Part 7: Cache tier
│   ├── cache-service.yaml        # Part 7: Cache Service
│   ├── postgres-statefulset.yaml # Part 7: Database StatefulSet + PVC
│   ├── postgres-service.yaml     # Part 7: headless Service
│   └── broken-pod.yaml           # Part 9: deliberately broken pod (delete after)
├── screenshots/                  # one screenshot per numbered Task
├── answers.md                    # answers to all 9 Checkpoint Questions
└── README.md                     # this file
```

---

## 2. Prerequisites (install these first)

You already have **Docker** from Assignment 1. Now add:

1. **kubectl** — the command-line tool that talks to Kubernetes.
   - Windows: `choco install kubernetes-cli` (if you use Chocolatey), or
     download the `.exe` from https://kubernetes.io/releases/download/
2. **Minikube** — runs a tiny single-node Kubernetes cluster on your PC.
   - Windows: `choco install minikube`, or download `minikube-windows-amd64.exe`
     and rename it to `minikube.exe`, then put it in your PATH.
3. **Docker Desktop** — must be running (Minikube uses Docker as its driver).

Verify each one:
```bash
docker --version
kubectl version --client
minikube version
```

---

## 3. Start the cluster

Open **Git Bash** and run:
```bash
minikube start --driver=docker
kubectl get nodes
```
`kubectl get nodes` should show one node with status `Ready`.

> Note: if you prefer, replace `--driver=docker` with the default or another
> driver on Windows. Docker driver is simplest because you already have it.

---

## 4. Part-by-part workflow

### Part 1 — Explore the cluster
```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -n kube-system
```
- Take a screenshot for **Task 1.1**.
- Fill in the component table for **Task 1.2** (see `answers.md`).

### Part 2 — Your first Pod
```bash
kubectl apply -f k8s/pod-frontend.yaml
kubectl get pods
kubectl describe pod frontend
kubectl logs frontend
kubectl port-forward pod/frontend 8080:80
```
Open `http://localhost:8080` in your browser → nginx welcome page. Screenshot for **Task 2.1**.
Answer **Q2** (see `answers.md`).

### Part 3 — Deployment + self-healing
```bash
kubectl apply -f k8s/deployment-frontend.yaml
kubectl get deployments
kubectl get pods -o wide
```
Pick one pod and delete it:
```bash
kubectl delete pod <pod-name>
kubectl get pods -w
```
Watch a new pod appear. Screenshot before/after for **Task 3.1**. Answer **Q3**.

### Part 4 — Scaling
```bash
kubectl scale deployment frontend --replicas=5
kubectl get pods -w
kubectl scale deployment frontend --replicas=2
```
Screenshot for **Task 4.1**. Answer **Q4**.

### Part 5 — Expose with a Service
```bash
kubectl apply -f k8s/service-frontend.yaml
kubectl get services
minikube service frontend --url
```
Open the printed URL in your browser → nginx page. Screenshot for **Task 5.1**. Answer **Q5**.

### Part 6 — Rolling update & rollback
```bash
kubectl set image deployment/frontend frontend=nginx:1.27-alpine
kubectl rollout status deployment/frontend
kubectl rollout undo deployment/frontend
kubectl rollout status deployment/frontend
```
Screenshot both rollout statuses for **Task 6.1**. Answer **Q6**.

### Part 7 — Full multi-container app
Apply the remaining tiers:
```bash
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/api-service.yaml
kubectl apply -f k8s/cache-deployment.yaml
kubectl apply -f k8s/cache-service.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/postgres-statefulset.yaml
kubectl get all
```
Screenshot `kubectl get all` for **Task 7.1**.

Then verify internal connectivity:
```bash
kubectl run debug --rm -it --image=busybox -- sh
```
Inside the debug pod:
```bash
wget -qO- http://api-service
nslookup cache-service
exit
```
Screenshot the output for **Task 7.2**. Answer **Q7**.

### Part 8 — Verify persistence
```bash
kubectl exec -it postgres-0 -- psql -U postgres -c \
"CREATE TABLE demo (id serial primary key, note text); INSERT INTO demo (note) VALUES ('lab6 test row');"
kubectl exec -it postgres-0 -- psql -U postgres -c "SELECT * FROM demo;"
kubectl delete pod postgres-0
kubectl get pods -w
kubectl exec -it postgres-0 -- psql -U postgres -c "SELECT * FROM demo;"
```
Screenshot showing the row is still there for **Task 8.1**. Answer **Q8**.

### Part 9 — Troubleshooting (break something on purpose)
```bash
minikube addons enable metrics-server
kubectl top pods
kubectl top nodes

kubectl apply -f k8s/broken-pod.yaml
kubectl get pods
kubectl describe pod broken-pod
```
Screenshot the STATUS and Events for **Task 9.1**. Answer **Q9**.
Clean up before continuing:
```bash
kubectl delete -f k8s/broken-pod.yaml
```

### Part 10 — Cleanup
```bash
kubectl delete -f k8s/
kubectl get all
minikube stop
```
Screenshot `kubectl get all` showing no application resources for **Task 10.1**.

---

## 5. Key `kubectl` commands cheat-sheet

| Command | What it does |
|---------|--------------|
| `kubectl get pods` | list pods |
| `kubectl get deployments` | list deployments |
| `kubectl get services` | list services |
| `kubectl get all` | show most resources at once |
| `kubectl describe pod <name>` | detailed info + events for a pod |
| `kubectl logs <pod>` | show a pod's log output |
| `kubectl apply -f file.yaml` | create/update resources from a file |
| `kubectl delete -f file.yaml` | delete resources from a file |
| `kubectl scale deployment <d> --replicas=N` | change replica count |
| `kubectl exec -it <pod> -- cmd` | run a command inside a pod |
| `kubectl port-forward pod/<pod> 8080:80` | temporary browser access to one pod |
| `kubectl top pods` | show CPU/memory usage (needs metrics-server) |

---

## 6. Submission

1. This `lab6` folder goes into the **same GitHub repository** you used for
   Assignment 1 (the one named your registration number), inside a `/lab6`
   folder. (Follow your lecturer's instruction if they said otherwise.)
2. Make sure `k8s/` contains all the YAML manifests.
3. Put one screenshot per numbered Task in `screenshots/`.
4. `answers.md` and `README.md` are already written for you.

---

## References

- Kubernetes docs: https://kubernetes.io/docs/
- Minikube docs: https://minikube.sigs.k8s.io/docs/
- Images used: nginx, kennethreitz/httpbin, redis, postgres (all on Docker Hub)
- Built as my own work for CCS3308 Lab 6.
