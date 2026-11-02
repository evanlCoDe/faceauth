import "./credit-card.css";

type CreditCardProps = {
  type: "gray-strip";
};

export default function CreditCard({ type }: CreditCardProps) {
  return (
    <div
      className={`faceauth-credit-card faceauth-credit-card--${type}`}
      role="img"
      aria-label="Gray FaceAuth credit card with a magnetic stripe and chip"
    >
      <div className="faceauth-credit-card__stripe" aria-hidden="true" />
      <div className="faceauth-credit-card__content">
        <div className="faceauth-credit-card__topline">
          <span className="faceauth-credit-card__brand">FaceAuth</span>
          <span className="faceauth-credit-card__mark" aria-hidden="true">
            <i />
            <i />
          </span>
        </div>
        <div className="faceauth-credit-card__chip" aria-hidden="true">
          <span />
        </div>
        <div className="faceauth-credit-card__bottomline">
          <span className="faceauth-credit-card__number" aria-hidden="true">
            •••• &nbsp; •••• &nbsp; •••• &nbsp; 2048
          </span>
          <span className="faceauth-credit-card__expiry" aria-hidden="true">
            MEMBER
          </span>
        </div>
      </div>
    </div>
  );
}
