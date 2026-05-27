1. Ensure data_product_setup has been ran for this DP in infra.
2. For local dev - Allow your Google user "Service account token creator" role on the TF DP service account.
3. gcloud auth application-default login --impersonate-service-account={YOUR_TF_SA}
4. Apply TF