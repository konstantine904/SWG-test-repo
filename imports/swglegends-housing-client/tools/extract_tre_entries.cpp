#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <unordered_set>
#include <vector>
#include <zlib.h>

namespace fs = std::filesystem;

uint32_t le32(const std::vector<uint8_t>& data, size_t offset) {
	return uint32_t(data.at(offset)) | (uint32_t(data.at(offset + 1)) << 8) |
		(uint32_t(data.at(offset + 2)) << 16) | (uint32_t(data.at(offset + 3)) << 24);
}

std::vector<uint8_t> inflate(const std::vector<uint8_t>& input, size_t expected) {
	std::vector<uint8_t> output(expected);
	uLongf size = output.size();
	if (uncompress(output.data(), &size, input.data(), input.size()) != Z_OK)
		throw std::runtime_error("zlib decompression failed");
	output.resize(size);
	return output;
}

int main(int argc, char** argv) {
	if (argc < 4) {
		std::cerr << "usage: extract_tre_entries TRE OUTPUT_DIR ENTRY...\\n";
		return 2;
	}
	std::ifstream in(argv[1], std::ios::binary);
	std::vector<uint8_t> data((std::istreambuf_iterator<char>(in)), {});
	if (data.size() < 36 || std::memcmp(data.data(), "EERT5000", 8) != 0) return 3;

	std::unordered_set<std::string> wanted;
	for (int i = 3; i < argc; ++i) wanted.insert(argv[i]);
	const auto records = le32(data, 8), recordStart = le32(data, 12);
	const auto recordCompression = le32(data, 16), recordCompressed = le32(data, 20);
	const auto nameCompression = le32(data, 24), nameCompressed = le32(data, 28), nameUncompressed = le32(data, 32);
	std::vector<uint8_t> names(data.begin() + recordStart + recordCompressed, data.begin() + recordStart + recordCompressed + nameCompressed);
	std::vector<uint8_t> index(data.begin() + recordStart, data.begin() + recordStart + recordCompressed);
	if (nameCompression == 2) names = inflate(names, nameUncompressed);
	if (recordCompression == 2) index = inflate(index, size_t(records) * 24);

	for (uint32_t i = 0; i < records; ++i) {
		const size_t record = size_t(i) * 24;
		const auto nameOffset = le32(index, record + 20);
		if (nameOffset >= names.size()) continue;
		const std::string name(reinterpret_cast<const char*>(names.data() + nameOffset), strnlen(reinterpret_cast<const char*>(names.data() + nameOffset), names.size() - nameOffset));
		if (!wanted.erase(name)) continue;
		const auto dataSize = le32(index, record + 4), dataOffset = le32(index, record + 8);
		const auto compression = le32(index, record + 12), compressed = le32(index, record + 16);
		if (dataOffset + compressed > data.size()) throw std::runtime_error("invalid entry offset: " + name);
		std::vector<uint8_t> entry(data.begin() + dataOffset, data.begin() + dataOffset + compressed);
		if (compression == 2) entry = inflate(entry, dataSize);
		const fs::path output = fs::path(argv[2]) / fs::path(name);
		fs::create_directories(output.parent_path());
		std::ofstream out(output, std::ios::binary);
		out.write(reinterpret_cast<const char*>(entry.data()), entry.size());
		std::cout << "extracted " << name << "\\n";
	}
	for (const auto& missing : wanted) std::cerr << "missing " << missing << "\\n";
	return wanted.empty() ? 0 : 1;
}
