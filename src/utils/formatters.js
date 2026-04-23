import { ethers } from "ethers";

// Конвертирует wei (bigint) в читаемый ETH
// Пример: 1000000000000000000n → "1.0"
export function weiToEth(wei) {
  if (!wei && wei !== 0n) return "0";
  return ethers.formatEther(wei);
}

// Сокращает адрес кошелька для отображения
// Пример: "0x1234567890abcdef..." → "0x1234...cdef"
export function formatAddress(address) {
  if (!address) return "";
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

// Конвертирует ETH строку в wei bigint
// Пример: "0.5" → 500000000000000000n
export function ethToWei(eth) {
  return ethers.parseEther(eth.toString());
}

// Форматирует число токенов красиво
// Пример: 1000000000000000000n → "1"
export function formatTokens(amount) {
  if (!amount && amount !== 0n) return "0";
  return ethers.formatUnits(amount, 18);
}