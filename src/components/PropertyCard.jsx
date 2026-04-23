import { Link } from "react-router-dom";
import { weiToEth } from "../utils/formatters";

function PropertyCard({ property }) {
  const { id, name, location, totalValue, tokenPrice, maxTokens, isActive } = property;

  return (
    <div style={{
      background: "var(--color-surface)",
      border: "1px solid var(--color-border)",
      borderRadius: "var(--radius-lg)",
      padding: "24px",
      display: "flex",
      flexDirection: "column",
      gap: "12px",
    }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
        <h3 style={{ fontSize: "18px", fontWeight: 600 }}>{name}</h3>
        <span style={{
          padding: "4px 10px",
          borderRadius: "20px",
          fontSize: "12px",
          background: isActive ? "rgba(34,197,94,0.1)" : "rgba(239,68,68,0.1)",
          color: isActive ? "var(--color-success)" : "var(--color-error)",
        }}>
          {isActive ? "Active" : "Closed"}
        </span>
      </div>

      <p style={{ color: "var(--color-text-secondary)", fontSize: "14px" }}>
        {location}
      </p>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px", marginTop: "8px" }}>
        <div>
          <p style={{ color: "var(--color-text-muted)", fontSize: "12px" }}>Total Value</p>
          <p style={{ fontWeight: 500 }}>{weiToEth(totalValue)} ETH</p>
        </div>
        <div>
          <p style={{ color: "var(--color-text-muted)", fontSize: "12px" }}>Token Price</p>
          <p style={{ fontWeight: 500 }}>{weiToEth(tokenPrice)} ETH</p>
        </div>
        <div>
          <p style={{ color: "var(--color-text-muted)", fontSize: "12px" }}>Total Shares</p>
          <p style={{ fontWeight: 500 }}>{maxTokens.toString()}</p>
        </div>
      </div>

      <Link
        to={`/properties/${id}`}
        style={{
          marginTop: "8px",
          padding: "10px",
          borderRadius: "var(--radius-sm)",
          background: "var(--color-primary)",
          color: "white",
          textAlign: "center",
          textDecoration: "none",
          fontSize: "14px",
          fontWeight: 500,
        }}>
        View & Invest
      </Link>
    </div>
  );
}

export default PropertyCard;