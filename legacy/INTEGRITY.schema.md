# INTEGRITY.tsv schema

Tab-separated, ASCII, header row required.

| Column | Required | Description |
|---|---|---|
| path | yes | Path relative to `legacy/` |
| sha256 | yes | Hex SHA-256 of file bytes, or `DIR` for directories, or `PENDING` |
| bytes | yes | Byte size, or `0` for DIR/PENDING |
| source_url | yes | Original URL or `local:` / `unknown` |
| captured_utc | yes | ISO-8601 UTC capture time |
| original_timestamp | no | Best-effort original mtime or page date |
| notes | no | Free text |

Product builds must ignore this tree. Validators only check schema presence and
that no product script sources packages from `legacy/binary-packages/`.
