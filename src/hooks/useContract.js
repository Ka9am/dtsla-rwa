import { ethers } from "ethers";
import { useWallet } from "./useWallet";
import { ADDRESSES } from "../contracts/addresses";
import MarketplaceABI from "../contracts/PropertyMarketplace.json";
import PropertyTokenABI from "../contracts/PropertyToken.json";
import RentalYieldABI from "../contracts/RentalYield.json";

// Возвращает инстанс контракта подключённый к нужному адресу и ABI
// Если кошелёк подключён — возвращает контракт с signer (для записи)
// Если нет — возвращает read-only контракт (только чтение)
export function useContract(contractName) {
  const { signer, provider } = useWallet();

  const configs = {
    marketplace: {
      address: ADDRESSES.marketplace,
      abi: MarketplaceABI,
    },
    rentalYield: {
      address: ADDRESSES.rentalYield,
      abi: RentalYieldABI,
    },
  };

  const config = configs[contractName];
  if (!config) throw new Error(`Неизвестный контракт: ${contractName}`);

  // Если есть signer — используем его (можно отправлять транзакции)
  // Если нет — используем provider (только чтение)
  const signerOrProvider = signer || provider;
  if (!signerOrProvider) return null;

  return new ethers.Contract(config.address, config.abi, signerOrProvider);
}

// Отдельная функция для токена конкретного свойства
// Каждый property имеет свой адрес токена
export function usePropertyTokenContract(tokenAddress) {
  const { signer, provider } = useWallet();

  const signerOrProvider = signer || provider;
  if (!signerOrProvider || !tokenAddress) return null;

  return new ethers.Contract(tokenAddress, PropertyTokenABI, signerOrProvider);
}