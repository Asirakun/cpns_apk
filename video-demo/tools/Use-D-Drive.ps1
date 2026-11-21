# Process-local settings. Does not change HOME, USERPROFILE or system settings.
$env:TEMP = 'D:\Project_Ai\animation_2\tools\temp'
$env:TMP = $env:TEMP
$env:PIP_CACHE_DIR = 'D:\Development\cache\pip'
$env:npm_config_cache = 'D:\Development\cache\npm'
$env:HF_HOME = 'D:\Development\cache\huggingface'
$env:HF_HUB_CACHE = 'D:\Development\cache\huggingface\hub'
$env:TORCH_HOME = 'D:\Development\cache\torch'
$env:TRITON_CACHE_DIR = 'D:\Development\cache\triton'
$env:NUMBA_CACHE_DIR = 'D:\Development\cache\numba'
foreach ($cachePath in @($env:TEMP,$env:PIP_CACHE_DIR,$env:npm_config_cache,$env:HF_HOME,$env:TORCH_HOME,$env:TRITON_CACHE_DIR,$env:NUMBA_CACHE_DIR)) { New-Item -ItemType Directory -Force -Path $cachePath | Out-Null }
