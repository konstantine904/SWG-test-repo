#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <zlib.h>

namespace fs = std::filesystem;

static uint32_t le32(const std::vector<uint8_t>& b, size_t o) {
	return uint32_t(b.at(o)) | (uint32_t(b.at(o + 1)) << 8) | (uint32_t(b.at(o + 2)) << 16) | (uint32_t(b.at(o + 3)) << 24);
}

static std::vector<uint8_t> inflate(const std::vector<uint8_t>& in, size_t expected) {
	std::vector<uint8_t> out(expected);
	uLongf size = out.size();
	if (uncompress(out.data(), &size, in.data(), in.size()) != Z_OK) throw std::runtime_error("zlib decompression failed");
	out.resize(size);
	return out;
}

int main(int argc, char** argv) {
	if (argc != 4) return 2;
	std::ifstream archive(argv[1], std::ios::binary);
	std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(archive)), {});
	if (bytes.size() < 36 || std::memcmp(bytes.data(), "EERT5000", 8) != 0) throw std::runtime_error("invalid TRE");
	std::ifstream wantedFile(argv[2]);
	std::vector<std::string> wanted;
	for (std::string line; std::getline(wantedFile, line);) if (!line.empty()) wanted.push_back(line);
	const auto records = le32(bytes, 8), recordStart = le32(bytes, 12), recordCompression = le32(bytes, 16), recordCompressed = le32(bytes, 20), nameCompression = le32(bytes, 24), nameCompressed = le32(bytes, 28), nameUncompressed = le32(bytes, 32);
	std::vector<uint8_t> recordBlock(bytes.begin() + recordStart, bytes.begin() + recordStart + recordCompressed);
	std::vector<uint8_t> nameBlock(bytes.begin() + recordStart + recordCompressed, bytes.begin() + recordStart + recordCompressed + nameCompressed);
	if (recordCompression == 2) recordBlock = inflate(recordBlock, size_t(records) * 24);
	if (nameCompression == 2) nameBlock = inflate(nameBlock, nameUncompressed);
	fs::path output(argv[3]); int extracted = 0;
	for (uint32_t i = 0; i < records; ++i) {
		const size_t record = size_t(i) * 24;
		const auto nameOffset = le32(recordBlock, record + 20);
		const std::string name(reinterpret_cast<const char*>(nameBlock.data() + nameOffset), strnlen(reinterpret_cast<const char*>(nameBlock.data() + nameOffset), nameBlock.size() - nameOffset));
		bool needed = false; for (const auto& target : wanted) if (name == target) { needed = true; break; }
		if (!needed) continue;
		const auto dataSize = le32(recordBlock, record + 4), dataOffset = le32(recordBlock, record + 8), dataCompression = le32(recordBlock, record + 12), dataCompressed = le32(recordBlock, record + 16);
		std::vector<uint8_t> data(bytes.begin() + dataOffset, bytes.begin() + dataOffset + dataCompressed);
		if (dataCompression == 2) data = inflate(data, dataSize);
		const fs::path destination = output / name;
		fs::create_directories(destination.parent_path());
		std::ofstream out(destination, std::ios::binary); out.write(reinterpret_cast<const char*>(data.data()), data.size());
		std::cout << name << "\n"; ++extracted;
	}
	return extracted == int(wanted.size()) ? 0 : 1;
}
