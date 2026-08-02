#include <algorithm>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <openssl/md5.h>
#include <string>
#include <vector>
#include <zlib.h>

namespace fs = std::filesystem;
constexpr const char* target = "object/tangible/wearables/robe/shared_robe_jedi_padawan.iff";
constexpr const char* oldAppearance = "appearance/robe_jedi_padawan_f.sat";
constexpr const char* blackAppearance = "appearance/robe_jedi_dark_s01_f.sat";

uint32_t le32(const std::vector<uint8_t>& bytes, size_t offset) {
    return uint32_t(bytes.at(offset)) | (uint32_t(bytes.at(offset + 1)) << 8) |
           (uint32_t(bytes.at(offset + 2)) << 16) | (uint32_t(bytes.at(offset + 3)) << 24);
}

uint32_t be32(const std::vector<uint8_t>& bytes, size_t offset) {
    return (uint32_t(bytes.at(offset)) << 24) | (uint32_t(bytes.at(offset + 1)) << 16) |
           (uint32_t(bytes.at(offset + 2)) << 8) | uint32_t(bytes.at(offset + 3));
}

void putLe32(std::ofstream& out, uint32_t value) {
    for (int shift = 0; shift < 32; shift += 8) out.put(static_cast<char>(value >> shift));
}

void putBe32(std::vector<uint8_t>& bytes, size_t offset, uint32_t value) {
    bytes.at(offset) = value >> 24;
    bytes.at(offset + 1) = value >> 16;
    bytes.at(offset + 2) = value >> 8;
    bytes.at(offset + 3) = value;
}

void increaseContainingIffChunks(std::vector<uint8_t>& bytes, size_t formStart, size_t needle, uint32_t delta) {
    const size_t formEnd = formStart + 8 + be32(bytes, formStart + 4);
    putBe32(bytes, formStart + 4, be32(bytes, formStart + 4) + delta);
    for (size_t offset = formStart + 12; offset + 8 <= formEnd;) {
        const uint32_t size = be32(bytes, offset + 4);
        const size_t end = offset + 8 + size;
        if (needle >= offset && needle < end) {
            if (std::memcmp(bytes.data() + offset, "FORM", 4) == 0)
                increaseContainingIffChunks(bytes, offset, needle, delta);
            else
                putBe32(bytes, offset + 4, size + delta);
            return;
        }
        offset = end;
    }
    throw std::runtime_error("could not locate the appearance IFF chunk");
}

uint32_t bzipCrc32(const std::string& value) {
    uint32_t crc = 0xffffffff;
    for (const unsigned char byte : value) {
        crc ^= uint32_t(byte) << 24;
        for (int bit = 0; bit < 8; ++bit)
            crc = (crc & 0x80000000) ? (crc << 1) ^ 0x04c11db7 : (crc << 1);
    }
    return crc ^ 0xffffffff;
}

void writePatchTre(const std::vector<uint8_t>& data) {
    const std::string name(target);
    const uint32_t dataSize = static_cast<uint32_t>(data.size());
    const uint32_t recordStart = 36 + dataSize;
    std::ofstream out("/tmp/project_kamino_black_padawan_robe.tre", std::ios::binary);
    out.write("EERT5000", 8);
    putLe32(out, 1); putLe32(out, recordStart); putLe32(out, 0); putLe32(out, 24);
    putLe32(out, 0); putLe32(out, static_cast<uint32_t>(name.size() + 1)); putLe32(out, static_cast<uint32_t>(name.size() + 1));
    out.write(reinterpret_cast<const char*>(data.data()), data.size());
    putLe32(out, bzipCrc32(name)); putLe32(out, dataSize); putLe32(out, 36); putLe32(out, 0); putLe32(out, dataSize); putLe32(out, 0);
    out.write(name.c_str(), name.size() + 1);
    unsigned char digest[MD5_DIGEST_LENGTH];
    MD5(data.data(), data.size(), digest);
    out.write(reinterpret_cast<const char*>(digest), sizeof(digest));
}

std::vector<uint8_t> inflate(const std::vector<uint8_t>& input, size_t expected) {
    std::vector<uint8_t> output(expected);
    uLongf size = output.size();
    if (uncompress(output.data(), &size, input.data(), input.size()) != Z_OK)
        throw std::runtime_error("zlib decompression failed");
    output.resize(size);
    return output;
}

int main() {
    for (const auto& entry : fs::directory_iterator("/tre")) {
        if (entry.path().extension() != ".tre") continue;
        std::ifstream in(entry.path(), std::ios::binary);
        std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(in)), {});
        if (bytes.size() < 36 || std::string(bytes.begin(), bytes.begin() + 8) != "EERT5000") continue;

        const auto records = le32(bytes, 8), recordStart = le32(bytes, 12);
        const auto recordCompression = le32(bytes, 16), recordCompressed = le32(bytes, 20);
        const auto nameCompression = le32(bytes, 24), nameCompressed = le32(bytes, 28), nameUncompressed = le32(bytes, 32);
        if (recordStart + recordCompressed + nameCompressed > bytes.size()) continue;

        std::vector<uint8_t> recordBlock(bytes.begin() + recordStart, bytes.begin() + recordStart + recordCompressed);
        std::vector<uint8_t> nameBlock(bytes.begin() + recordStart + recordCompressed,
                                       bytes.begin() + recordStart + recordCompressed + nameCompressed);
        if (recordCompression == 2) recordBlock = inflate(recordBlock, records * 24);
        if (nameCompression == 2) nameBlock = inflate(nameBlock, nameUncompressed);
        if (recordBlock.size() < records * 24) continue;

        for (uint32_t index = 0; index < records; ++index) {
            const size_t record = index * 24;
            const auto dataSize = le32(recordBlock, record + 4), dataOffset = le32(recordBlock, record + 8);
            const auto dataCompression = le32(recordBlock, record + 12), dataCompressed = le32(recordBlock, record + 16), nameOffset = le32(recordBlock, record + 20);
            if (nameOffset >= nameBlock.size() || dataOffset + dataCompressed > bytes.size()) continue;
            const char* start = reinterpret_cast<const char*>(nameBlock.data() + nameOffset);
            const size_t remaining = nameBlock.size() - nameOffset;
            const std::string name(start, strnlen(start, remaining));
            if (name != target) continue;

            std::vector<uint8_t> data(bytes.begin() + dataOffset, bytes.begin() + dataOffset + dataCompressed);
            if (dataCompression == 2) data = inflate(data, dataSize);
            const auto appearance = std::search(data.begin(), data.end(), oldAppearance, oldAppearance + std::strlen(oldAppearance));
            if (appearance == data.end()) throw std::runtime_error("the Padawan robe appearance reference was not found");
            const size_t appearanceOffset = appearance - data.begin();
            if (std::memcmp(data.data(), "FORM", 4) != 0) throw std::runtime_error("the Padawan robe template is not a valid IFF form");
            const uint32_t delta = std::strlen(blackAppearance) - std::strlen(oldAppearance);
            increaseContainingIffChunks(data, 0, appearanceOffset, delta);
            data.erase(data.begin() + appearanceOffset, data.begin() + appearanceOffset + std::strlen(oldAppearance) + 1);
            data.insert(data.begin() + appearanceOffset, blackAppearance, blackAppearance + std::strlen(blackAppearance) + 1);
            writePatchTre(data);
            std::cout << "Created /tmp/project_kamino_black_padawan_robe.tre from " << entry.path() << "\n";
            return 0;
        }
    }
    std::cerr << "Template not found\n";
    return 1;
}
