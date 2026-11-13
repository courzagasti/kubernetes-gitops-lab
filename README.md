# Laboratorio GitOps local: GitHub + Actions + GHCR + Terraform + Argo CD + Kubernetes

## Requisitos
Windows, Docker Desktop con Kubernetes (`docker-desktop`) en Ready, Terraform >=1.9, Git y cuenta GitHub Free.

**Importante:** se usa un repositorio **público** y la imagen GHCR debe configurarse como **pública**. No publiques secretos. GitHub Actions NO accede a tu Kubernetes local: Argo CD descarga los manifiestos desde GitHub.

## 1. Crear repositorio
Crear en GitHub un repositorio público llamado `kubernetes-gitops-lab` **vacío** (sin README ni .gitignore automáticos).
Extraer este ZIP y abrir PowerShell en su carpeta.

```powershell
.\scripts\configure-repo.ps1 -Owner TU_USUARIO_GITHUB
git init
git branch -M main
git add .
git commit -m "Initial GitOps lab"
git remote add origin https://github.com/TU_USUARIO_GITHUB/kubernetes-gitops-lab.git
git push -u origin main
```

Si GitHub solicita credenciales, autenticarse mediante Git Credential Manager. En GitHub > Settings > Actions > General > Workflow permissions, seleccionar **Read and write permissions** (si está disponible) para permitir que el workflow actualice el manifiesto. El workflow también requiere `packages: write` para GHCR.

## 2. Verificar CI
En GitHub > Actions, comprobar que el workflow `CI Docker GitOps` terminó correctamente. En GitHub > Packages, localizar el paquete `kubernetes-gitops-lab` y cambiar su visibilidad a **Public** (en configuración del paquete). Comprobar que el workflow actualizó `kubernetes/deployment.yaml` con el SHA real.

**Nota:** el primer `git push` ejecuta el pipeline; si hay un error de permisos en el `git push` del bot, revisar Workflow permissions y reejecutar el workflow. Las protecciones de rama pueden impedir ese push automático; para este laboratorio no configurar protección en `main`.

## 3. Instalar Argo CD con Terraform (desde Windows)
```powershell
kubectl config current-context
kubectl get nodes
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
cd ..
kubectl get pods -n argocd
```

La instalación requiere acceso a internet a Helm/registry y puede tardar algunos minutos. Se fija la versión del chart para reproducibilidad. Terraform usa el kubeconfig local `~/.kube/config` y el contexto `docker-desktop`.

## 4. Crear la Application GitOps
Una vez que los Pods de Argo CD estén Ready:
```powershell
kubectl apply -f argocd/application.yaml
kubectl get applications -n argocd
kubectl get pods -n gitops-lab
kubectl get svc -n gitops-lab
```

Este `kubectl apply` inicial configura Argo CD una sola vez. Los cambios posteriores de la aplicación se sincronizan automáticamente.

## 5. Ver aplicación en Windows
En una terminal separada:
```powershell
kubectl port-forward -n gitops-lab svc/gitops-demo 5000:80
```
Abrir http://localhost:5000 . No dependemos de NodePort ni de `imagePullPolicy: Never`.

## 6. Ver interfaz de Argo CD
En otra terminal:
```powershell
kubectl port-forward -n argocd svc/argocd-server 8080:443
```
Abrir https://localhost:8080 (certificado local/autofirmado). Usuario `admin`. Para obtener la contraseña inicial desde PowerShell:
```powershell
$secret = kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}'
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($secret))
```
No subir esa contraseña al repositorio.

## 7. Probar el cambio automático
Editar `app/app.js` y reemplazar `Version 1` por `Version 2`:
```powershell
git pull --rebase origin main
git add app/app.js
git commit -m "Demo version 2"
git push
```
Esperar el workflow y la sincronización de Argo CD. Refrescar http://localhost:5000 . **No ejecutar `kubectl apply`** para actualizar la aplicación.

## 8. Diagnóstico
```powershell
kubectl get applications -n argocd
kubectl get deployments,pods,svc -n gitops-lab
kubectl describe pod -n gitops-lab -l app=gitops-demo
kubectl logs -n gitops-lab deploy/gitops-demo
```
Si la imagen no se puede descargar, confirmar visibilidad pública en GHCR. Si Argo CD no sincroniza, comprobar que el repositorio es público y que `argocd/application.yaml` apunta al usuario correcto.

## 9. Limpieza
```powershell
kubectl delete -f argocd/application.yaml
kubectl delete namespace gitops-lab --ignore-not-found
cd terraform
terraform destroy
```

No borrar `terraform.tfstate` antes de `terraform destroy`. Los recursos en GitHub y GHCR se eliminan por separado si ya no se necesitan.

## Notas de seguridad y alcance
- Laboratorio de aprendizaje, no configuración de producción.
- No se requiere PAT ni secretos de acceso al clúster en GitHub.
- La actualización del manifiesto por el pipeline usa `GITHUB_TOKEN` con permisos de escritura; para producción conviene separar repositorios y aplicar revisiones/PR.
- Argo CD usa `prune` y `selfHeal`, por lo que puede revertir cambios manuales en los recursos gestionados.
