from fastapi import FastAPI, Request
from pydantic import BaseModel
import subprocess
import uvicorn

app = FastAPI(title="K8s Auto-Remediation Demo")

class Alert(BaseModel):
    status: str
    labels: dict
    annotations: dict

@app.post("/alert")
async def handle_alert(request: Request):
    data = await request.json()
    alerts = data.get("alerts", [])
    
    for alert in alerts:
        status = alert.get("status")
        labels = alert.get("labels", {})
        annotations = alert.get("annotations", {})

        alert_name = labels.get("alertname")
        pod_name = labels.get("pod")
        namespace = labels.get("namespace")
        deployment_name = labels.get("deployment")

        print(f"[INFO] Alert received: {alert_name} | Pod: {pod_name} | NS: {namespace} | Status: {status}")

        if status != "firing":
            continue  # Only handle firing alerts

        # -------------------------------
        # CrashLoopBackOff Auto-Remediation
        # -------------------------------
        if alert_name == "PodCrashLooping" and pod_name:
            try:
                subprocess.run(
                    ["kubectl", "delete", "pod", pod_name, "-n", namespace],
                    check=True
                )
                print(f"✅ Pod {pod_name} deleted successfully for CrashLoopBackOff remediation")
            except subprocess.CalledProcessError as e:
                print(f"❌ Failed to delete pod {pod_name}: {e}")

        # -------------------------------
        # High CPU Auto-Scaling
        # -------------------------------
        elif alert_name == "HighPodCPU" and deployment_name:
            try:
                # Get current replicas
                result = subprocess.run(
                    ["kubectl", "get", "deploy", deployment_name, "-n", namespace, "-o", "jsonpath={.spec.replicas}"],
                    capture_output=True,
                    text=True,
                    check=True
                )
                current_replicas = int(result.stdout)
                new_replicas = current_replicas + 1  # scale up by 1
                subprocess.run(
                    ["kubectl", "scale", "deploy", deployment_name, f"--replicas={new_replicas}", "-n", namespace],
                    check=True
                )
                print(f"✅ Deployment {deployment_name} scaled from {current_replicas} → {new_replicas} due to High CPU")
            except subprocess.CalledProcessError as e:
                print(f"❌ Failed to scale deployment {deployment_name}: {e}")

    return {"message": "Alerts processed"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
