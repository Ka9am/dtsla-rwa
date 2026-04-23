import { useState } from "react";
import { useParams, Link } from "react-router-dom";
import { useProperties } from "../hooks/useProperties";
import { useInvestment } from "../hooks/useInvestment";
import { useWallet } from "../hooks/useWallet";
import TransactionStatus from "../components/TransactionStatus";
import { weiToEth } from "../utils/formatters";
import { TX_STATUS } from "../utils/constants";

function PropertyDetailPage() {
  const { id } = useParams();
  const { properties, loading } = useProperties();
  const { isConnected, connect } = useWallet();
  const { invest, txStatus, txHash, error, reset } = useInvestment(Number(id));
  const [ethAmount, setEthAmount] = useState("");

  const property = properties[Number(id)];

  if (loading) return (
    <div style={{ padding: "48px 0", color: "var(--color-text-secondary)" }}>
      Loading...
    </div>
  );

  if (!property) return (
    <div style={{ padding: "48px 0" }}>
      <p style={{ color: "var(--color-error)" }}>Property not found</p>
      <Link to="/properties">← Back to properties</Link>
    </div>
  );

  const tokenPrice = weiToEth(property.tokenPrice);
  const tokensToReceive = ethAmount
    ? Math.floor(parseFloat(ethAmount) / parseFloat(tokenPrice))
    : 0;

  const handleInvest = async () => {
    if (!ethAmount || parseFloat(ethAmount) <= 0) return;
    await invest(ethAmount);
    setEthAmount("");
  };

  const isPending = txStatus === TX_STATUS.SIGNING || txStatus === TX_STATUS.PENDING;

  return (
    <div style={{ padding: "48px 0", maxWidth: "600px" }}>
      <Link to="/properties" style={{ color: "var(--color-text-secondary)", fontSize: "14px" }}>
        ← Back to properties
      </Link>

      <h1 style={{ marginTop: "24px", marginBottom: "8px" }}>{property.name}</h1>
      <p style={{ color: "var(--color-text-secondary)", marginBottom: "32px" }}>
        {property.location}
      </p>

      <div style={{
        display: "grid",
        gridTemplateColumns: "1fr 1fr",
        gap: "16px",
        marginBottom: "32px",
      }}>
        {[
          { label: "Total Value", value: `${weiToEth(property.totalValue)} ETH` },
          { label: "Token Price", value: `${tokenPrice} ETH` },
          { label: "Total Shares", value: property.maxTokens.toString() },
          { label: "Status", value: property.isActive ? "Active" : "Closed" },
        ].map(({ label, value }) => (
          <div key={label} style={{
            background: "var(--color-surface)",
            border: "1px solid var(--color-border)",
            borderRadius: "var(--radius-md)",
            padding: "16px",
          }}>
            <p style={{ color: "var(--color-text-muted)", fontSize: "12px" }}>{label}</p>
            <p style={{ fontWeight: 500, marginTop: "4px" }}>{value}</p>
          </div>
        ))}
      </div>

      {/* Инвестиционная форма */}
      <div style={{
        background: "var(--color-surface)",
        border: "1px solid var(--color-border)",
        borderRadius: "var(--radius-lg)",
        padding: "24px",
      }}>
        <h3 style={{ marginBottom: "16px" }}>Invest in this property</h3>

        {!isConnected ? (
          <button
            onClick={connect}
            style={{
              width: "100%",
              padding: "12px",
              borderRadius: "var(--radius-sm)",
              border: "none",
              background: "var(--color-primary)",
              color: "white",
              fontSize: "16px",
            }}>
            Connect Wallet to Invest
          </button>
        ) : (
          <>
            <div style={{ marginBottom: "16px" }}>
              <label style={{ color: "var(--color-text-secondary)", fontSize: "14px" }}>
                Amount (ETH)
              </label>
              <input
                type="number"
                value={ethAmount}
                onChange={(e) => { setEthAmount(e.target.value); reset(); }}
                placeholder={`Min: ${tokenPrice} ETH`}
                step={tokenPrice}
                style={{
                  width: "100%",
                  padding: "12px",
                  marginTop: "8px",
                  borderRadius: "var(--radius-sm)",
                  border: "1px solid var(--color-border)",
                  background: "var(--color-bg)",
                  color: "var(--color-text-primary)",
                  fontSize: "16px",
                }}
              />
            </div>

            {tokensToReceive > 0 && (
              <p style={{ color: "var(--color-text-secondary)", fontSize: "14px", marginBottom: "16px" }}>
                You will receive: <strong style={{ color: "var(--color-text-primary)" }}>
                  {tokensToReceive} tokens
                </strong>
              </p>
            )}

            <button
              onClick={handleInvest}
              disabled={isPending || !ethAmount || tokensToReceive === 0}
              style={{
                width: "100%",
                padding: "12px",
                borderRadius: "var(--radius-sm)",
                border: "none",
                background: "var(--color-primary)",
                color: "white",
                fontSize: "16px",
                opacity: isPending || !ethAmount ? 0.7 : 1,
              }}>
              {isPending ? "Processing..." : "Invest"}
            </button>

            <TransactionStatus status={txStatus} txHash={txHash} error={error} />
          </>
        )}
      </div>
    </div>
  );
}

export default PropertyDetailPage;