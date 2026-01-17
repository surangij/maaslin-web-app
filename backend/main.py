# backend/main.py
from fastapi import FastAPI, UploadFile, File
import subprocess
import os
import uuid

app = FastAPI()


@app.post("/run-maaslin")
async def run_maaslin(
    features: UploadFile = File(...),
    metadata: UploadFile = File(...)
):
    # Create a unique job folder
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

    # Create output folder
    output_folder = os.path.join(job_folder, "output")
    os.makedirs(output_folder, exist_ok=True)

    # Default MaAsLin3 parameters
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

    # R script path (relative to main.py)
    r_script_path = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "250710_MaAslin3.R")
    )

    # Call the R script
    r_args = [
        "Rscript", r_script_path,
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

    result = subprocess.run(r_args, capture_output=True, text=True)

    # Collect output files
    output_files = []
    if os.path.exists(output_folder):
        for root, dirs, files in os.walk(output_folder):
            for file in files:
                # Return relative paths for clarity
                output_files.append(os.path.relpath(os.path.join(root, file), job_folder))

    # Return job info
    return {
        "job_id": job_id,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "return_code": result.returncode,
        "output_files": output_files
    }


@app.get("/health")
def health():
    """Health check endpoint"""
    return {"status": "ok"}
