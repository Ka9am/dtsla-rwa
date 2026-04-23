import { useProperties } from "../hooks/useProperties";
import PropertyCard from "../components/PropertyCard";

function PropertiesPage() {
  const { properties, loading, error } = useProperties();

  if (loading) return (
    <div style={{ padding: "48px 0", color: "var(--color-text-secondary)" }}>
      Loading properties...
    </div>
  );

  if (error) return (
    <div style={{ padding: "48px 0", color: "var(--color-error)" }}>
      {error}
    </div>
  );

  return (
    <div style={{ padding: "48px 0" }}>
      <h1 style={{ marginBottom: "32px" }}>Properties</h1>

      {properties.length === 0 ? (
        <p style={{ color: "var(--color-text-secondary)" }}>
          No properties listed yet.
        </p>
      ) : (
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))",
          gap: "24px",
        }}>
          {properties.map((property) => (
            <PropertyCard key={property.id} property={property} />
          ))}
        </div>
      )}
    </div>
  );
}

export default PropertiesPage;