from fastapi import FastAPI, UploadFile, File
import subprocess
import os
import uuid
import shutil

app = FastAPI()

@app.post("/run-maaslin")
async def run_maaslin(
    features: UploadFile = File(...),
    metadata: UploadFile = File(...)
):
    # Create a unique folder for this job
    job_id = str(uuid.uuid4())
    job_folder = f"/tmp/{job_id}"
    os.makedirs(job_folder, exist_ok=True)

    # Save uploaded files
    features_path = os.path.join(job_folder, "features.tsv")
    metadata_path = os.path.join(job_folder, "metadata.tsv")
    with open(features_path, "wb") as f:
        f.write(await features.read())
    with open(metadata_path, "wb") as f:
        f.write(await metadata.read())

    # Output folder
    output_folder = os.path.join(job_folder, "output")
    os.makedirs(output_folder, exist_ok=True)

    # Set simple default parameters
    formula = "~ disease"
    normalization = "TSS"
    transform = "LOG"
    augment = "TRUE"
    standardize = "TRUE"
    max_significance = 0.1
    median_comparison_abundance = "TRUE"
    median_comparison_prevalence = "FALSE"
    max_pngs = 250
    cores = 1

    # Call the R script
    r_args = [
        "Rscript", "../250710_MaAslin3.R",
        features_path,
        metadata_path,
        output_folder,
        formula,
        normalization,
        transform,
        augment,
        standardize,
        str(max_significance),
        median_comparison_abundance,
        median_comparison_prevalence,
        str(max_pngs),
        str(cores)
    ]

    result = subprocess.run(
        r_args, capture_output=True, text=True
    )

    # Collect output files
    output_files = []
    if os.path.exists(output_folder):
        for root, dirs, files in os.walk(output_folder):
            for file in files:
                output_files.append(file)

    # Return R stdout, stderr, and created files
    return {
        "job_id": job_id,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "return_code": result.returncode,
        "output_files": output_files
    }

@app.get("/health")
def health():
    return {"status": "ok"}
