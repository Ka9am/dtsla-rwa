import { createContext, useState, useEffect, useCallback } from "react";
import { ethers } from "ethers";
import { SEPOLIA_CHAIN_ID } from "../contracts/addresses";

// Создаём контекст — это как "глобальная переменная" для React
export const WalletContext = createContext(null);

export function WalletProvider({ children }) {
  const [address, setAddress] = useState(null);
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [chainId, setChainId] = useState(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState(null);

  // Проверяем правильная ли сеть (должна быть Sepolia)
  const isCorrectNetwork = chainId === SEPOLIA_CHAIN_ID;

  // Подключение кошелька
  const connect = useCallback(async () => {
    if (!window.ethereum) {
      setError("MetaMask не установлен. Установите MetaMask и попробуйте снова.");
      return;
    }

    try {
      setIsConnecting(true);
      setError(null);

      // Запрашиваем доступ к аккаунту — MetaMask покажет popup
      const browserProvider = new ethers.BrowserProvider(window.ethereum);
      const accounts = await browserProvider.send("eth_requestAccounts", []);

      if (accounts.length === 0) {
        setError("Аккаунт не выбран");
        return;
      }

      const network = await browserProvider.getNetwork();
      const userSigner = await browserProvider.getSigner();

      setProvider(browserProvider);
      setSigner(userSigner);
      setAddress(accounts[0]);
      setChainId(Number(network.chainId));

      // Если не Sepolia — просим переключиться
      if (Number(network.chainId) !== SEPOLIA_CHAIN_ID) {
        await switchToSepolia();
      }

    } catch (err) {
      setError(err.message || "Ошибка подключения");
    } finally {
      setIsConnecting(false);
    }
  }, []);

  // Переключение на Sepolia
  const switchToSepolia = async () => {
    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: "0xaa36a7" }], // 11155111 в hex
      });
    } catch (err) {
      // Если Sepolia не добавлена в MetaMask — добавляем
      if (err.code === 4902) {
        await window.ethereum.request({
          method: "wallet_addEthereumChain",
          params: [{
            chainId: "0xaa36a7",
            chainName: "Sepolia Testnet",
            rpcUrls: ["https://rpc.sepolia.org"],
            nativeCurrency: { name: "ETH", symbol: "ETH", decimals: 18 },
            blockExplorerUrls: ["https://sepolia.etherscan.io"],
          }],
        });
      }
    }
  };

  // Отключение кошелька
  const disconnect = useCallback(() => {
    setAddress(null);
    setProvider(null);
    setSigner(null);
    setChainId(null);
  }, []);

  // При загрузке страницы — проверяем уже подключён ли пользователь
  useEffect(() => {
    if (!window.ethereum) return;

    const checkConnection = async () => {
      try {
        const browserProvider = new ethers.BrowserProvider(window.ethereum);
        // eth_accounts не показывает popup — просто читает
        const accounts = await browserProvider.send("eth_accounts", []);
        if (accounts.length > 0) {
          const network = await browserProvider.getNetwork();
          const userSigner = await browserProvider.getSigner();
          setProvider(browserProvider);
          setSigner(userSigner);
          setAddress(accounts[0]);
          setChainId(Number(network.chainId));
        }
      } catch (err) {
        console.error("Ошибка проверки подключения:", err);
      }
    };

    checkConnection();

    // Слушаем события MetaMask
    const handleAccountsChanged = (accounts) => {
      if (accounts.length === 0) {
        disconnect();
      } else {
        setAddress(accounts[0]);
      }
    };

    const handleChainChanged = () => {
      // При смене сети — перезагружаем страницу
      window.location.reload();
    };

    window.ethereum.on("accountsChanged", handleAccountsChanged);
    window.ethereum.on("chainChanged", handleChainChanged);

    // Убираем слушатели когда компонент размонтируется
    return () => {
      window.ethereum.removeListener("accountsChanged", handleAccountsChanged);
      window.ethereum.removeListener("chainChanged", handleChainChanged);
    };
  }, [disconnect]);

  const value = {
    address,
    provider,
    signer,
    chainId,
    isConnected: !!address,
    isCorrectNetwork,
    isConnecting,
    error,
    connect,
    disconnect,
  };

  return (
    <WalletContext.Provider value={value}>
      {children}
    </WalletContext.Provider>
  );
}