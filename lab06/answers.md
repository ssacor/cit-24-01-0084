# Lab 6 Answers — Kubernetes Fundamentals with Minikube

My written answers to all the Checkpoint Questions (Q1–Q9) plus the
Task 1.2 component table.

---

## Task 1.2 — Pods I saw and the cluster component they represent

When I ran `kubectl get pods -n kube-system`, I saw these pods. Each one
maps to a cluster component from the lecture:

| Pod name (kube-system) | Cluster component it runs | Part of |
|------------------------|---------------------------|---------|
| `kube-apiserver-*`      | API Server               | Control plane |
| `etcd-*`                | etcd                     | Control plane |
| `kube-scheduler-*`      | Scheduler                | Control plane |
| `kube-controller-manager-*` | Controller Manager    | Control plane |
| `kube-proxy-*`          | kube-proxy               | Worker node (each node) |
| `coredns-*`             | CoreDNS (cluster DNS)    | Support/addon |
| `storage-provisioner`   | Storage provisioner      | Support/addon (Minikube) |

**Components that did NOT appear as pods, and why:**
- **kubelet** — it is not a container; it runs directly as a system service
  on each node and talks to the container runtime. So it has no pod.
- **Container runtime (containerd / docker)** — this is the software that
  actually runs containers; it lives on each node outside of Kubernetes
  itself, so it does not appear as a pod either.

---

## Q1 — Difference between the Control Plane and a Worker Node

The **control plane** is the "brain" of the cluster. It makes all the big
decisions: which pods to run, where to put them, and keeping everything
in the desired state. It includes the API Server, Scheduler, Controller
Manager, and etcd.

A **worker node** is the "body". It is the actual machine where my
application pods run. Each worker runs a **kubelet** (which talks to the
control plane) and a **kube-proxy** (network rules). So: control plane
**thinks and decides**, worker nodes **do the work**.

---

## Q2 — Did the Pod's IP change after recreation? Why?

Yes. When I deleted the pod (`kubectl delete pod frontend`) and recreated
it from the same manifest, it came back with a **different IP address**.

This is because Pods are **ephemeral** — they are temporary and disposable.
Every new pod is a brand-new object, so Kubernetes gives it a brand-new IP.
This is exactly why we cannot rely on a pod's IP directly, and why the
lecture says pods are ephemeral.

---

## Q3 — Control-loop: what happened when I deleted a pod?

Step by step, using the lecture's **control-loop model**:

1. **Desired State** — the Deployment says "I want 3 replicas of frontend".
2. **Controller watches** — the Deployment controller (a Controller Manager)
   constantly watches the cluster and counts how many pods actually exist.
3. **Actual State** — I deleted one pod, so now only 2 exist.
4. **Gap Detected** — the controller sees 2 pods, but the desired state is 3.
   It detects a gap of 1 missing pod.
5. **Reconcile** — the controller creates a brand-new replacement pod to
   bring the count back up to 3.

The replacement appeared in about **a few seconds**. This is **self-healing**.

---

## Q4 — Why can I scale the frontend without touching the database?

Because each tier is **its own Deployment**, and they are **independent**.
They talk to each other only through **Services**, never through pod IPs
directly. So when I scale the frontend up or down, I only change that one
Deployment — the database Deployment is untouched.

The lecture's "Applications Are Multiple Containers" slide makes this point:
each service can scale **independently**, because they are decoupled
(separate, isolated, connected by stable Service addresses).

---

## Q5 — Port-forward vs Service

- **Port-forward (Part 2):** I connect my browser directly to ONE single pod.
  It is only for quick, temporary testing. If that pod dies, the connection
  breaks. It does not load-balance.

- **Service (Part 5):** It is a stable, permanent "front door" that sits in
  front of ALL the pods. It keeps ONE fixed address and forwards traffic to
  whichever pod is healthy. If a pod dies, the Service just sends traffic to
  another one.

**Why Services matter:** Pods are ephemeral and get new IPs when replaced.
If my app used pod IPs directly, the address would break every time a pod
was replaced. A Service gives a **fixed address** that never changes, so
other apps can always find this tier no matter how many times pods restart.

---

## Q6 — Why is update-and-rollback harder with Docker Compose?

Docker Compose can only describe a fixed set of containers. It has **no
built-in rolling update** and **no automatic rollback**. To update with
Compose I would have to manually stop everything, start the new version,
and if it failed I would have to manually put the old version back — and
users experience downtime during that time.

Kubernetes does this **automatically and safely**: `kubectl set image`
updates pods one at a time (a rolling update) while keeping the app
available, and `kubectl rollout undo` instantly rolls back if something is
wrong. This is one of the things from the lecture's list of things
**Docker Compose Cannot** do safely.

---

## Q7 — Why do frontend/API use a Deployment but the database uses a StatefulSet?

| Feature | Deployment (frontend/API/cache) | StatefulSet (database) |
|---------|--------------------------------|------------------------|
| **State** | Stateless (no saved data) | Stateful (must keep data) |
| **Pod names** | Random (`frontend-abc123`) | Stable & ordered (`postgres-0`) |
| **Storage** | No persistent disk (or shared) | Each pod gets its OWN persistent disk (PVC) |
| **Ordering** | Pods created/stopped in any order | Created and stopped in order (0, 1, 2...) |
| **Scaling** | Safe to scale up/down freely | Scaling is controlled |

The **database needs to keep its data forever**, even if the pod is deleted
and recreated. A StatefulSet gives it a **stable name** (`postgres-0`) and a
**persistent volume** that survives pod recreation. If we used a plain
Deployment, each new pod would lose its identity and its data.

---

## Q8 — Would the data have survived without a PersistentVolumeClaim?

**No.** If postgres had been a plain Deployment **without** a PVC, then when
I deleted the pod, Kubernetes would create a new pod with a **fresh, empty
disk**. The database files (my `demo` table and row) would have been **lost**,
because they were stored on the old pod's temporary disk.

The PVC is what keeps the data: the disk is attached to the *volume*, not
to the pod, so it survives pod deletion and is remounted into the new pod.
That is exactly what Part 8 proved — the row was still there after the pod
was deleted and recreated.

---

## Q9 — What status did the broken pod show?

The broken pod showed a status of **ImagePullBackOff** (and while waiting,
sometimes `ErrImagePull`).

This status is **related to but not exactly one of** the statuses listed in
the lecture's Pod Status table (Running / Pending / CrashLoopBackOff /
OOMKilled). The lecture lists `CrashLoopBackOff`, which is what happens when
a pod *starts and then keeps crashing*. My pod **never started at all**,
because Kubernetes **could not download the image** (`nginx:definitely-not-a-real-tag`
does not exist). So instead it went into `ImagePullBackOff`, which means:
"the image pull failed, Kubernetes is backing off and retrying." The Events
section showed `Failed to pull image ... repository does not exist`.
