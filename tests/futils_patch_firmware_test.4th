\ tests/futils_patch_firmware_test.4th — обёртка fmix для tests/futils/patch_firmware_test.4th
\ fmix test сканирует каталог tests/ нерекурсивно (test-read-dir в fmix_test.4th),
\ поэтому тесты из tests/futils/ без обёртки не запускаются ни в fmix test,
\ ни в pre-commit/pre-push. Обёртка лишь включает настоящий тест.
s" futils/patch_firmware_test.4th" included
