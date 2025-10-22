# DB — Password Rotation (Application User)

**Goal:** Rotate WordPress DB credentials safely with minimal downtime.

---

## Preconditions
- Admin access to the Managed MySQL instance.
- Ability to update Kubernetes secret `wp-db` and restart the app Deployment.

## Steps
1. **Create new DB user/password** with the same privileges as the current app user.
2. **Update Kubernetes secret** with new user/password **alongside** the old ones (if chart supports dual envs) or prepare for quick cutover.
3. **Roll the deployment**:
   ```bash
   kubectl -n app apply -f <updated-secret>.yaml
   kubectl -n app rollout restart deploy/wp
   kubectl -n app rollout status deploy/wp --timeout=180s
   ```
4. **Remove old credentials** from the DB and the secret after validation.

## Notes
- If chart cannot hold dual creds, time the change during a low-traffic window.
- Keep the CA bundle unchanged.
