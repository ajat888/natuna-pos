#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# push.sh — Auto analyze + commit + push
# Cara pakai:
#   ./push.sh              → commit dengan pesan default
#   ./push.sh "fix: xxx"   → commit dengan pesan custom
# ============================================================

set -e  # berhenti kalau ada perintah gagal

# Warna biar enak dibaca
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "=================================================="
echo "  🔍 STEP 1: Cek Error Kode (flutter analyze)"
echo "=================================================="
echo ""

# Jalankan analyze. Kalau ada ERROR (bukan warning/info), berhenti.
# Output disimpan dulu, biar bisa diperiksa
ANALYZE_OUT=$(flutter analyze 2>&1) || true

# Filter: baris yang mengandung "error •" itu yang fatal
if echo "$ANALYZE_OUT" | grep -qiE "^\s*error\s+•"; then
    echo -e "${RED}❌ Ada ERROR di kode! Push dibatalkan.${NC}"
    echo ""
    echo "Detail error:"
    echo "$ANALYZE_OUT" | grep -iE "^\s*error\s+•"
    echo ""
    echo "=================================================="
    echo -e "${YELLOW}💡 Cara baca error:${NC}"
    echo "   'error • ... • lib/pages/file.dart:211:41'"
    echo "   Artinya: buka file.dart baris 211 kolom 41"
    echo "=================================================="
    exit 1
fi

# Kalau hanya warning/info, tetap lanjut tapi beri tahu
if echo "$ANALYZE_OUT" | grep -qiE "^\s*(warning|info)\s+•"; then
    echo -e "${YELLOW}⚠️  Ada warning (bukan error fatal), tapi tetap lanjut.${NC}"
    echo "   Kalau ingin lihat detail: flutter analyze"
    echo ""
fi

# Kalau bersih total
if echo "$ANALYZE_OUT" | grep -q "No issues found"; then
    echo -e "${GREEN}✅ Kode bersih, tidak ada error!${NC}"
fi

echo ""
echo "=================================================="
echo "  📦 STEP 2: Cek Perubahan"
echo "=================================================="
echo ""

# Cek apakah ada perubahan
if git diff --quiet && git diff --cached --quiet; then
    echo -e "${YELLOW}ℹ️  Tidak ada perubahan untuk di-commit.${NC}"
    echo "   (File tidak berubah sejak commit terakhir)"
    exit 0
fi

echo "File yang berubah:"
git status --short
echo ""

# Ambil pesan commit dari argumen, atau default
COMMIT_MSG="${1:-update}"

echo "=================================================="
echo "  📝 STEP 3: Commit + Push"
echo "=================================================="
echo ""
echo "Pesan commit: $COMMIT_MSG"
echo ""

# Konfirmasi
read -p "Lanjut commit + push? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Dibatalkan.${NC}"
    exit 0
fi

echo ""
echo "→ Menjalankan: git add -A"
git add -A

echo "→ Menjalankan: git commit -m \"$COMMIT_MSG\""
git commit -m "$COMMIT_MSG"

echo "→ Menjalankan: git push"
git push

echo ""
echo "=================================================="
echo -e "${GREEN}✅ SELESAI! Kode berhasil di-push.${NC}"
echo "=================================================="
echo ""
echo "💡 Kalau pakai Vercel: tunggu 2-3 menit,"
echo "   lalu cek dashboard Vercel untuk status build."
echo "   Kalau pakai GitHub Actions: cek tab 'Actions' di repo."
echo ""
