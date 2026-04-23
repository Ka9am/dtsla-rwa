import { useState } from "react";
import { ethers } from "ethers";
import { useWallet } from "./useWallet";
import { TX_STATUS } from "../utils/constants";
import { ADDRESSES } from "../contracts/addresses";
import MarketplaceABI from "../contracts/PropertyMarketplace.json";

export function useInvestment(propertyId) {
  const { signer, isConnected } = useWallet();
  const [txStatus, setTxStatus] = useState(TX_STATUS.IDLE);
  const [txHash, setTxHash] = useState(null);
  const [error, setError] = useState(null);

  const invest = async (ethAmount) => {
    if (!isConnected) {
      setError("Подключите кошелёк");
      return;
    }

    try {
      setError(null);
      setTxStatus(TX_STATUS.SIGNING);

      const marketplace = new ethers.Contract(
        ADDRESSES.marketplace,
        MarketplaceABI,
        signer
      );

      // Конвертируем ETH строку в wei
      const valueInWei = ethers.parseEther(ethAmount.toString());

      // Отправляем транзакцию — MetaMask покажет popup
      const tx = await marketplace.invest(propertyId, { value: valueInWei });
      setTxHash(tx.hash);
      setTxStatus(TX_STATUS.PENDING);

      // Ждём подтверждения в блокчейне
      await tx.wait();
      setTxStatus(TX_STATUS.CONFIRMED);

    } catch (err) {
      console.error("Ошибка инвестирования:", err);
      setTxStatus(TX_STATUS.FAILED);
      // Показываем понятное сообщение об ошибке
      if (err.code === 4001) {
        setError("Транзакция отклонена пользователем");
      } else if (err.message?.includes("insufficient funds")) {
        setError("Недостаточно ETH на балансе");
      } else {
        setError(err.reason || err.message || "Ошибка транзакции");
      }
    }
  };

  const reset = () => {
    setTxStatus(TX_STATUS.IDLE);
    setTxHash(null);
    setError(null);
  };

  return { invest, txStatus, txHash, error, reset };
}