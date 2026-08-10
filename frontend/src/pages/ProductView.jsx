import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { getProduct, listProducts } from '../api';
import ProductPage from '../components/ProductPage';

export default function ProductView({ onAddToCart }) {
  const { id } = useParams();
  const location = useLocation();
  const initialProduct = location.state?.product || null;
  const [product, setProduct] = useState(initialProduct);
  const [relatedProducts, setRelatedProducts] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    let mounted = true;
    if (!id) return;
    getProduct(id)
      .then((p) => mounted && setProduct(p))
      .catch(() => {
        if (!mounted) return;
        if (!initialProduct) {
          setProduct(null);
        }
      });
    return () => {
      mounted = false;
    };
  }, [id, initialProduct]);

  useEffect(() => {
    let mounted = true;
    if (!product?.id) {
      setRelatedProducts([]);
      return () => {
        mounted = false;
      };
    }

    const categories = (product.categories || []).map((category) => String(category).toLowerCase());

    listProducts()
      .then((items) => {
        if (!mounted) return;
        const related = items
          .filter((item) => String(item.id) !== String(product.id))
          .filter((item) =>
            (item.categories || []).some((category) =>
              categories.includes(String(category).toLowerCase())
            )
          )
          .slice(0, 4);
        setRelatedProducts(related);
      })
      .catch(() => {
        if (mounted) {
          setRelatedProducts([]);
        }
      });

    return () => {
      mounted = false;
    };
  }, [product]);

  if (!product) return <div style={{ padding: '1rem' }}>Loading...</div>;

  return (
    <ProductPage
      product={product}
      relatedProducts={relatedProducts}
      onBack={() => navigate(-1)}
      onAddToCart={onAddToCart}
    />
  );
}
