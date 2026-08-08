import React from 'react';
import PropTypes from 'prop-types';
import styles from './product-card.module.css';
import ImageWithFallback from './ImageWithFallback';
import { formatRpCents } from '../utils/currency';

export default function ProductCard({ product, onSelect, onAddToCart }) {
  const [isAdding, setIsAdding] = React.useState(false);
  const price = formatRpCents(product.price_cents || 0);
  const categoryText = (product.categories || []).slice(0, 3).join(', ');

  function handleAddToCart(event) {
    event.stopPropagation();
    if (isAdding) return;

    setIsAdding(true);
    window.setTimeout(() => {
      onAddToCart();
      setIsAdding(false);
    }, 320);
  }

  return (
    <article className={styles.card}>
      <button
        type="button"
        className={styles.cardButton}
        onClick={onSelect}
        aria-label={`View ${product.title}`}
      >
        <div className={styles.media}>
          <ImageWithFallback
            src={product.images?.[0]}
            alt={product.title}
            className={styles.cardImage}
          />
        </div>
        <div className={styles.cardBody}>
          {categoryText ? <p className={styles.categoryLine}>{categoryText}</p> : null}
          <h3>{product.title}</h3>
          <div className={styles.cardFooter}>
            <p className={styles.price}>{price}</p>
          </div>
        </div>
      </button>
      <button
        type="button"
        className={styles.addButton}
        onClick={handleAddToCart}
        aria-label={`Add ${product.title} to cart`}
        disabled={isAdding}
      >
        {isAdding ? 'Adding...' : 'Add to cart'}
      </button>
    </article>
  );
}

ProductCard.propTypes = {
  product: PropTypes.shape({
    id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
    title: PropTypes.string.isRequired,
    price_cents: PropTypes.number.isRequired,
    images: PropTypes.arrayOf(PropTypes.string),
    categories: PropTypes.arrayOf(PropTypes.string),
  }).isRequired,
  onSelect: PropTypes.func.isRequired,
  onAddToCart: PropTypes.func.isRequired,
};
