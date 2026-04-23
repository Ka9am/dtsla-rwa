import { useState, useEffect } from "react";
import { ethers } from "ethers";
import { useWallet } from "./useWallet";
import { TX_STATUS } from "../utils/constants";
import { ADDRESSES } from "../contracts/addresses";
import RentalYieldABI from "../contracts/RentalYield.json";

export function useYield() {
  const { signer, address, isConnected } = useWallet();
  const [pendingYield, setPendingYield] = useState(null);
  const [txStatus, setTxStatus] = useState(TX_STATUS.IDLE);
  const [txHash, setTxHash] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  const getContract = () => {
    if (!signer) return null;
    return new ethers.Contract(ADDRESSES.rentalYield, RentalYieldABI, signer);
  };

  const fetchPendingYield = async () => {
    if (!address) return;
    try {
      setLoading(true);
      const contract = getContract();
      if (!contract) return;
      const amount = await contract.calculatePendingYield(address);
      setPendingYield(amount);
    } catch (err) {
      console.error("Ошибка получения yield:", err);
    } finally {
      setLoading(false);
    }
  };

  const claimYield = async () => {
    if (!isConnected) return;
    try {
      setError(null);
      setTxStatus(TX_STATUS.SIGNING);
      const contract = getContract();
      const tx = await contract.claimYield();
      setTxHash(tx.hash);
      setTxStatus(TX_STATUS.PENDING);
      await tx.wait();
      setTxStatus(TX_STATUS.CONFIRMED);
      await fetchPendingYield();
    } catch (err) {
      setTxStatus(TX_STATUS.FAILED);
      if (err.code === 4001) {
        setError("Транзакция отклонена");
      } else {
        setError(err.reason || err.message || "Ошибка");
      }
    }
  };

  useEffect(() => {
    if (isConnected) fetchPendingYield();
  }, [address, isConnected]);

  return { pendingYield, loading, txStatus, txHash, error, claimYield };
}