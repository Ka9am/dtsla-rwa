import { useState, useEffect } from "react";
import { ethers } from "ethers";
import { ADDRESSES } from "../contracts/addresses";
import MarketplaceABI from "../contracts/PropertyMarketplace.json";

// Читаем свойства напрямую без useContract
// потому что нам нужен read-only доступ даже без кошелька
export function useProperties() {
  const [properties, setProperties] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchProperties = async () => {
    try {
      setLoading(true);
      setError(null);

      // Подключаемся к Sepolia через публичный RPC
      // Это работает даже без MetaMask
      // Используем MetaMask если доступен, иначе публичный RPC
    const provider = window.ethereum
    ? new ethers.BrowserProvider(window.ethereum)
    : new ethers.JsonRpcProvider("https://ethereum-sepolia-rpc.publicnode.com");

      const marketplace = new ethers.Contract(
        ADDRESSES.marketplace,
        MarketplaceABI,
        provider
      );

      // Получаем количество свойств
      const count = await marketplace.propertyCount();
      const countNum = Number(count);

      if (countNum === 0) {
        setProperties([]);
        return;
      }

      // Загружаем все свойства параллельно
      const promises = Array.from({ length: countNum }, (_, i) =>
        marketplace.properties(i)
      );
      const results = await Promise.all(promises);

      // Форматируем данные
      const formatted = results.map((prop, index) => ({
        id: index,
        name: prop[1],
        location: prop[2],
        totalValue: prop[3],
        tokenPrice: prop[4],
        maxTokens: prop[5],
        tokenAddress: prop[6],
        isActive: prop[7],
        }));

      setProperties(formatted);
    } catch (err) {
      console.error("Ошибка загрузки свойств:", err);
      setError("Не удалось загрузить свойства. Попробуйте позже.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProperties();
  }, []);

  return { properties, loading, error, refetch: fetchProperties };
}