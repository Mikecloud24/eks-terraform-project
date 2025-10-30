# PowerShell helper to test dynamic provisioning using the default StorageClass.
# This script:
#  - applies tests/pvc.yaml
#  - waits for the PVC to be Bound (120s timeout)
#  - prints PVC and PV details
#  - does not cleanup automatically; delete the PVC manually when ready

Set-StrictMode -Version Latest

Write-Host "Applying PVC manifest..."
kubectl apply -f tests/pvc.yaml

Write-Host "Waiting for PVC to become Bound (120s)..."
$waitOutput = kubectl wait --for=condition=bound pvc/ebs-test-pvc --timeout=120s 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "PVC did not become Bound within timeout. Output:" -ForegroundColor Yellow
    Write-Host $waitOutput
    exit 1
}

Write-Host "PVC is Bound. Showing details..." -ForegroundColor Green
kubectl get pvc ebs-test-pvc -o wide

Write-Host "Listing PVs created by the cluster (may include others)..."
kubectl get pv -o wide | Select-String -Pattern "ebs-test-pvc|gp" -SimpleMatch

Write-Host "Test complete. To clean up run: kubectl delete pvc ebs-test-pvc" -ForegroundColor Cyan
