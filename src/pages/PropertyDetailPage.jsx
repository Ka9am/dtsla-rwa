import { useParams } from "react-router-dom";
function PropertyDetailPage() {
  const { id } = useParams();
  return (
    <div style={{ padding: "48px 0" }}>
      <h1>Property #{id}</h1>
    </div>
  );
}
export default PropertyDetailPage;