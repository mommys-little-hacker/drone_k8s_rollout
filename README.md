# drone_k8s_rollout

## Descrption

Drone.io plugin to perform secure releases to Kubernetes.

How it works:

* Authorize in cluster
* Update images for specified objects
* Test if all new containers are up and running
* Print logs and rollback if not

## Usage

Default value is in brackets

* user (admin) - k8s API user. If you do not use RBAC, then it is most likely to be "admin";
* token - k8s API autorization token. Possible ways to obtain it are described later;
* addr - k8s API server address. Possible ways to obtain it are described later;
* ca - base64 encoded k8s API server CA certificate; You MUST specify it, as it will secure your communication with API;
* kind (deployment) - object type in kubernetes. Can be one of (but not limited to): deployment, statefulset, daemonset;
* object - name of the object to be updated;
* img_cnts - array of containers in k8s object to be updated;
* img_names - array of container images to use. Must match the order of img_cnts;
* img_tags - array of tags of images for update. Order must match with img_names;
* namespace - k8s namespace;
* logs_if_fail (true) - print logs of containers if deployment failed to roll out;
* revert_if_fail (true) - undo deployment if it failed to roll out;
* rollout_timeout (10m) - timeout to wait until rollout is done;
* debug (false) - enable debug mode.

## Example

The following example updates with fresh images the website deployment with 2 containers ("dynamic" with httpd, and "static" with nginx):

```
  deploy_to_k8s:
    image: jackthestripper/drone_k8s_rollout
    user: admin
    token: 32tx2u6Y1rlD2sHcpxstCmP1m4taE1fb
    addr: https://api.k8s.example.com
    namespace: default
    kind: deployment
    object: website
    img_cnts:
    - dynamic
    - static
    img_names:
    - httpd
    - nginx
    img_tags:
    - 2.4.33
    - 1.13.12
    ca: "LS0tLS1CRUdJRiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMwekNDQWJ1Z0F3SUJBZ0lNRlNTbzZ4bytxFmxYWFVweU1BMEdDU3FHU0liM0RRRUJDd1VBTUJVeEV6QVIKQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13SGhjTk1UZ3dOREV3TVRBeE9ESXhXaGNOTWpnd05EQTVNVEF4T0RJeApXakFWTVJNd0VRWURWUVFERX5wcmRXSmxjbTVsZEdWek1JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUThBCk1JSUJDZ0tDQVFFQXdDZlhvZmIwMHQ2ZG9xMm1MZzlreUxjTE5lTEYzVlM0R29lRUNOMCtuaityall1THRaYlkKOStiV0JBMW1Ua3NWS3JGcUFob2l5K1g0dkRzYWcyWmExMm80cVlRci9FWGs2cVRtRnluT0s1NkpLdWJoVXNoRAp3QjQxTDgvaXJ1NmdNUWs2a2lYbnVuN2UzS25iemJlZml5QytVc2I5TFR4UWRPMldvTm5tQVpZV2g3Qj64YUJmCm5vSGRHZE4wQTBwZlNBZU1SYWZjb0M3QmNyQldiQlUzMG4xMlM3bFdUTkl0OU82SWMwVUt2NzFXTFlDeFNOQm8KSGhkaEZzZzlaWjQ4dVBPQkRzRlBxUXFsTUdtWEtUVW1ydS8zTG1qSnRFV1h5WVJ0QjJvOVlreGdTUUV4Yi9FZwpIdjNGQ1dYblY2NVNDUTRnQTZHL2tINUV4N1hoMnlybGh3SURBUUFCb3lNd0lUQU9CZ05WSFE4QkFmOEVCQU1DCkFRWXdEd1lEVlIwVEFRSC9CQVV3QXdwQi96QU5CZ2txaGtpRzd3MEJBUXNGQUFPQ0FRRUFjWkVIMEc4enFmU2QKR1Q5RDMraVVDdnl5akxrY2xLUjhRWENEVGdxVXB3TGNaN0FuUU1uN2xkalk0UjJHR3lnMnZteWkyZ1AzbktxRQpPWldGTk5WYjUxOHkyN3c2bXdTUnVuUHZ1VzdzT0NFS2I3MmhzN1dFZUNVUGZ3Ni9kVUFueDNzVW1CV243RzVTCjhBRjBvc0lQZVNzeXhVZnNpc25ucG43MGVuRHdtV3k3SzdhYXJvb3hFNk0zMDhNWFROeGh0bW9SOVFPQzR3QUgKWk80SzM0eFpLK2xoTHZNcFpZSHVyeEZUZFJiR3JhTHNKVjZ6YlRHdURlSTAwckY3MVdq5MHJlUkF0NVZ6TEgyNwppclJMUlRZVFphQmpuTHlrcGVYbGw3eEFnamxpWVM1L3B1RHZsMFk0elBxMFI4U3NjYXRtUTB0SnVIa2tQaElkCktXalVlMjM2TFE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
```

This step translates into following commands (without authentication):

```
kubectl set image deployment website dynamic=httpd:2.4.33 static=nginx:1.13.12 --namespace=$k8s_ns
kubectl rollout status deployment website --wait --namespace=$k8s_ns --request-timeout=10m \
  || kubectl rollout undo deployment website --namespace=$k8s_ns
```

Using secrets to store access credentials for kubernetes is possible. Add the following pattern to your step (with corresponding secrets configured) to utilize them:

```
secrets:
- k8s_ca
- k8s_user
- k8s_token
- k8s_addr
```

## Considerations

Number of elements in arrays (img_cnts, img_names, img_tags) should always be the same.

CA certificate is mandatory to secure communication with server. No, I will not add an option to allow insecure communication.

All the necessary information can be found in your kubernetes config (typically, ~/.kube/config). You can also kops to get API token:

```
kops get secrets kube --type secret -oplaintext
```

Enabling debug mode will print secrets to stdout, so everyone who has access to oyur server may see it.
