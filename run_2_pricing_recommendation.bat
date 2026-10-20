
@echo off
cd /d E:\DataEngineer\DBT\belajar_dbt

call E:\DataEngineer\venv_dbt\Scripts\activate.bat

if errorlevel 1 (
    echo Failed to activate virtual environment.
    exit /b 1
)

dbt run --select 2_fct_price_recommendation

if errorlevel 1 (
    echo Pricing recommendation FAILED.
    exit /b 1
)

echo Pricing recommendation completed successfully.
exit /b 0
