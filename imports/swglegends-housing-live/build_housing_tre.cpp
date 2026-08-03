#include <algorithm>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <openssl/md5.h>
#include <string>
#include <utility>
#include <vector>

namespace fs = std::filesystem;

void le32(std::ofstream& out, uint32_t value) {
	for (int shift = 0; shift < 32; shift += 8) out.put(static_cast<char>(value >> shift));
}

uint32_t crc32(const std::string& value) {
	uint32_t crc = 0xffffffff;
	for (unsigned char byte : value) {
		crc ^= uint32_t(byte) << 24;
		for (int bit = 0; bit < 8; ++bit) crc = (crc & 0x80000000) ? (crc << 1) ^ 0x04c11db7 : (crc << 1);
	}
	return crc ^ 0xffffffff;
}

struct Entry { std::string name; std::vector<char> data; uint32_t offset; uint32_t nameOffset; };

int main(int argc, char** argv) {
	if (argc != 3) return 2;
	const fs::path input(argv[1]), output(argv[2]);
	std::vector<Entry> entries;
	for (const auto& relative : std::vector<std::string>{
		"object/building/player/shared_player_house_wod_ns_hut.iff",
		"object/building/player/shared_player_house_wod_sm_hut.iff",
		"object/tangible/deed/player_house_deed/shared_wod_ns_hut_deed.iff",
		"object/tangible/deed/player_house_deed/shared_wod_sm_hut_deed.iff",
		"object/building/player/shared_player_house_tree_house_01.iff",
		"object/building/player/shared_player_house_tree_house_02.iff",
		"object/building/player/shared_player_house_tcg_8_yoda_house.iff",
		"object/building/player/shared_player_house_mustafar_lg.iff",
		"object/tangible/deed/player_house_deed/shared_tree_house_01_deed.iff",
		"object/tangible/deed/player_house_deed/shared_tree_house_02_deed.iff",
		"object/tangible/deed/player_house_deed/shared_player_house_tcg_8_yoda_house.iff",
		"object/tangible/deed/player_house_deed/shared_mustafar_house_lg.iff",
		"footprint/building/player/shared_player_house_tree_house_01.sfp",
		"footprint/building/player/shared_player_house_tree_house_02.sfp",
		"footprint/building/player/shared_player_house_tcg_yoda_house.sfp",
		"footprint/building/player/shared_player_mustafar_house_lg.sfp",
		"appearance/ply_all_tree_house.pob",
		"appearance/ply_all_tree_house_tall.pob",
		"appearance/ply_all_yoda_house.pob",
		"appearance/ply_all_house_lg_s03_fp1.pob"}) {
		std::ifstream in(input / relative, std::ios::binary);
		if (!in) throw std::runtime_error("missing " + relative);
		entries.push_back({relative, std::vector<char>((std::istreambuf_iterator<char>(in)), {}), 0, 0});
	}
	for (const auto& alias : std::vector<std::pair<std::string, std::string>>{
		{"object/building/player/player_house_tree_house_01.iff", "object/building/player/shared_player_house_tree_house_01.iff"},
		{"object/building/player/player_house_tree_house_02.iff", "object/building/player/shared_player_house_tree_house_02.iff"},
		{"object/building/player/player_house_tcg_8_yoda_house.iff", "object/building/player/shared_player_house_tcg_8_yoda_house.iff"},
		{"object/building/player/player_house_mustafar_lg.iff", "object/building/player/shared_player_house_mustafar_lg.iff"},
		{"object/tangible/deed/player_house_deed/tree_house_01_deed.iff", "object/tangible/deed/player_house_deed/shared_tree_house_01_deed.iff"},
		{"object/tangible/deed/player_house_deed/tree_house_02_deed.iff", "object/tangible/deed/player_house_deed/shared_tree_house_02_deed.iff"},
		{"object/tangible/deed/player_house_deed/yoda_house_deed.iff", "object/tangible/deed/player_house_deed/shared_player_house_tcg_8_yoda_house.iff"},
		{"object/tangible/deed/player_house_deed/mustafar_house_lg_deed.iff", "object/tangible/deed/player_house_deed/shared_mustafar_house_lg.iff"}}) {
		std::ifstream in(input / alias.second, std::ios::binary);
		if (!in) throw std::runtime_error("missing " + alias.second);
		entries.push_back({alias.first, std::vector<char>((std::istreambuf_iterator<char>(in)), {}), 0, 0});
	}
	std::sort(entries.begin(), entries.end(), [](const Entry& left, const Entry& right) { return crc32(left.name) < crc32(right.name); });
	uint32_t dataSize = 0, namesSize = 0;
	for (auto& entry : entries) { entry.offset = 36 + dataSize; dataSize += entry.data.size(); entry.nameOffset = namesSize; namesSize += entry.name.size() + 1; }
	std::ofstream out(output, std::ios::binary);
	out.write("EERT5000", 8);
	le32(out, entries.size()); le32(out, 36 + dataSize); le32(out, 0); le32(out, entries.size() * 24); le32(out, 0); le32(out, namesSize); le32(out, namesSize);
	for (const auto& entry : entries) out.write(entry.data.data(), entry.data.size());
	for (const auto& entry : entries) { le32(out, crc32(entry.name)); le32(out, entry.data.size()); le32(out, entry.offset); le32(out, 0); le32(out, entry.data.size()); le32(out, entry.nameOffset); }
	for (const auto& entry : entries) out.write(entry.name.c_str(), entry.name.size() + 1);
	for (const auto& entry : entries) {
		unsigned char digest[MD5_DIGEST_LENGTH];
		MD5(reinterpret_cast<const unsigned char*>(entry.data.data()), entry.data.size(), digest);
		out.write(reinterpret_cast<const char*>(digest), sizeof(digest));
	}
	std::cout << "wrote " << output << " with " << entries.size() << " entries\\n";
}
