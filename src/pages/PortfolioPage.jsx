import { useWallet } from "../hooks/useWallet";
import { useProperties } from "../hooks/useProperties";
import { ethers } from "ethers";
import { useState, useEffect } from "react";
import { weiToEth } from "../utils/formatters";
import { ADDRESSES } from "../contracts/addresses";
import MarketplaceABI from "../contracts/PropertyMarketplace.json";

function PortfolioPage() {
  const { isConnected, connect, address, signer } = useWallet();
  const { properties, loading } = useProperties();
  const [balances, setBalances] = useState({});
  const [loadingBalances, setLoadingBalances] = useState(false);

  useEffect(() => {
    if (!isConnected || !signer || properties.length === 0) return;

    const fetchBalances = async () => {
      setLoadingBalances(true);
      try {
        const marketplace = new ethers.Contract(
          ADDRESSES.marketplace,
          MarketplaceABI,
          signer
        );

        const results = await Promise.all(
          properties.map((p) =>
            marketplace.getInvestorBalance(p.id, address)
          )
        );

        const balanceMap = {};
        properties.forEach((p, i) => {
          balanceMap[p.id] = results[i];
        });
        setBalances(balanceMap);
      } catch (err) {
        console.error("Ошибка загрузки балансов:", err);
      } finally {
        setLoadingBalances(false);
      }
    };

    fetchBalances();
  }, [isConnected, address, signer, properties]);

  if (!isConnected) {
    return (
      <div style={{ padding: "48px 0" }}>
        <h1 style={{ marginBottom: "16px" }}>My Portfolio</h1>
        <p style={{ color: "var(--color-text-secondary)", marginBottom: "24px" }}>
          Connect your wallet to see your holdings.
        </p>
        <button
          onClick={connect}
          style={{
            padding: "12px 24px",
            borderRadius: "var(--radius-sm)",
            border: "none",
            background: "var(--color-primary)",
            color: "white",
            fontSize: "16px",
          }}>
          Connect Wallet
        </button>
      </div>
    );
  }

  if (loading || loadingBalances) {
    return (
      <div style={{ padding: "48px 0", color: "var(--color-text-secondary)" }}>
        Loading portfolio...
      </div>
    );
  }

  const myProperties = properties.filter(
    (p) => balances[p.id] && balances[p.id] > 0n
  );

  return (
    <div style={{ padding: "48px 0" }}>
      <h1 style={{ marginBottom: "32px" }}>My Portfolio</h1>

      {myProperties.length === 0 ? (
        <div style={{
          background: "var(--color-surface)",
          border: "1px solid var(--color-border)",
          borderRadius: "var(--radius-lg)",
          padding: "32px",
          textAlign: "center",
        }}>
          <p style={{ color: "var(--color-text-secondary)" }}>
            You don't own any property tokens yet.
          </p>
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
          {myProperties.map((property) => (
            <div key={property.id} style={{
              background: "var(--color-surface)",
              border: "1px solid var(--color-border)",
              borderRadius: "var(--radius-lg)",
              padding: "24px",
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
            }}>
              <div>
                <h3 style={{ marginBottom: "4px" }}>{property.name}</h3>
                <p style={{ color: "var(--color-text-secondary)", fontSize: "14px" }}>
                  {property.location}
                </p>
                <p style={{ color: "var(--color-text-muted)", fontSize: "13px", marginTop: "4px" }}>
                  Token price: {weiToEth(property.tokenPrice)} ETH
                </p>
              </div>
              <div style={{ textAlign: "right" }}>
                <p style={{ color: "var(--color-text-muted)", fontSize: "12px" }}>
                  Your tokens
                </p>
                <p style={{ fontSize: "28px", fontWeight: 600 }}>
                  {balances[property.id].toString()}
                </p>
                <p style={{ color: "var(--color-text-secondary)", fontSize: "13px" }}>
                  of {property.maxTokens.toString()} total
                </p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default PortfolioPage;