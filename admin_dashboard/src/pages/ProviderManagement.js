import React, { useState, useEffect, useCallback, useRef } from 'react';
import { 
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, 
  Paper, TextField, Button, Select, MenuItem, FormControl, InputLabel,
  Grid, Card, CardContent, Typography, Tabs, Tab, IconButton, Chip, Dialog, DialogTitle, DialogContent, DialogActions, Box, Avatar, Snackbar, Alert, FormControlLabel, Switch, Menu
} from '@mui/material';
import RestaurantIcon from '@mui/icons-material/Restaurant';
import LocalPharmacyIcon from '@mui/icons-material/LocalPharmacy';
import ShoppingBasketIcon from '@mui/icons-material/ShoppingBasket';
import EditIcon from '@mui/icons-material/Edit';
import SearchIcon from '@mui/icons-material/Search';
import AddIcon from '@mui/icons-material/Add';
import PictureAsPdfIcon from '@mui/icons-material/PictureAsPdf';
import AddAPhotoIcon from '@mui/icons-material/AddAPhoto';
import VisibilityIcon from '@mui/icons-material/Visibility';
import EmailIcon from '@mui/icons-material/Email';
import PhoneIcon from '@mui/icons-material/Phone';
import LocationOnIcon from '@mui/icons-material/LocationOn';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import Divider from '@mui/material/Divider';
import DeleteIcon from '@mui/icons-material/Delete';
import AddCircleIcon from '@mui/icons-material/AddCircle';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import CategoryIcon from '@mui/icons-material/Category';
import PrintIcon from '@mui/icons-material/Print';
import * as XLSX from 'xlsx';
import htmlDocx from 'html-docx-js/dist/html-docx';
import './ProviderManagement.css';
import axios from 'axios';
import CloseIcon from '@mui/icons-material/Close';
import MapIcon from '@mui/icons-material/Map';
import StoreIcon from '@mui/icons-material/Store';
import ScheduleIcon from '@mui/icons-material/Schedule';
import BusinessIcon from '@mui/icons-material/Business';
import DescriptionIcon from '@mui/icons-material/Description';
import SaveIcon from '@mui/icons-material/Save';
import CancelIcon from '@mui/icons-material/Cancel';
import PersonIcon from '@mui/icons-material/Person';
import LockIcon from '@mui/icons-material/Lock';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// تعريف أيقونة مخصصة للماركر
const markerIcon = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon-2x.png',
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-shadow.png',
  shadowSize: [41, 41],
  iconSize: [25, 41],
});

// مكون لتحديث الموقع عند النقر على الخريطة
function LocationMarker({ position, setPosition }) {
  useMapEvents({
    click(e) {
      setPosition([e.latlng.lat, e.latlng.lng]);
    },
  });

  return position ? <Marker position={position} icon={markerIcon} /> : null;
}

const ProviderManagement = () => {
  const [providers, setProviders] = useState([]);
  const [filteredProviders, setFilteredProviders] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [providerType, setProviderType] = useState('all');
  const [tabValue, setTabValue] = useState(0);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [editProvider, setEditProvider] = useState(null);
  const [editFields, setEditFields] = useState({ name: '', phone: '', email: '', address: '', isVerified: false, horaires_ouverture: '', description: '', logo: null });
  const [editLogoPreview, setEditLogoPreview] = useState(null);
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [newProvider, setNewProvider] = useState({
    username: '',
    password: '',
    email: '',
    telephone: '',
    adresse: '',
    type_fournisseur: '',
    nom_commerce: '',
    description: '',
    adresse_commerce: '',
    horaires_ouverture: '',
    latitude: 18.0735, // موقع افتراضي (نواكشوط)
    longitude: -15.9582,
    logo: null,
    logo_preview: null,
    photo_profile: null,
    photo_profile_preview: null
  });
  const [errorDialog, setErrorDialog] = useState({ open: false, message: '', status: '', url: '', errors: null });
  const [successSnackbar, setSuccessSnackbar] = useState({ open: false, message: '' });
  const [errorSnackbar, setErrorSnackbar] = useState({ open: false, message: '' });
  const [totalRevenue, setTotalRevenue] = useState(0);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [viewProvider, setViewProvider] = useState(null);
  const [productsDialogOpen, setProductsDialogOpen] = useState(false);
  const [products, setProducts] = useState([]);
  const [filteredProducts, setFilteredProducts] = useState([]);
  const [productSearchTerm, setProductSearchTerm] = useState('');
  const [addProductDialogOpen, setAddProductDialogOpen] = useState(false);
  const [editProductDialogOpen, setEditProductDialogOpen] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [newProduct, setNewProduct] = useState({
    nom: '',
    description: '',
    prix: '',
    categorie: '',
    disponible: true,
    image: null
  });
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [productToDelete, setProductToDelete] = useState(null);
  const [openPrintDialog, setOpenPrintDialog] = useState(false);
  const [printProviders, setPrintProviders] = useState([]);
  const [exportAnchorEl, setExportAnchorEl] = useState(null);
  const [openExportDialog, setOpenExportDialog] = useState(false);
  const [exportType, setExportType] = useState('');
  const [activeTab, setActiveTab] = useState(0);
  const mapRef = useRef(null);

  const filterProviders = useCallback(() => {
    let result = [...providers];
    switch(tabValue) {
      case 1:
        result = result.filter(provider => provider.type === 'Restaurant');
        break;
      case 2:
        result = result.filter(provider => provider.type === 'Pharmacie');
        break;
      case 3:
        result = result.filter(provider => provider.type === 'Supermarché');
        break;
      default:
        break;
    }
    if (searchTerm) {
      result = result.filter(provider => 
        provider.nom.toLowerCase().includes(searchTerm.toLowerCase()) || 
        provider.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        provider.telephone.includes(searchTerm)
      );
    }
    if (providerType !== 'all') {
      const isVerified = providerType === 'verified';
      result = result.filter(provider => provider.statut === (isVerified ? 'Vérifié' : 'Non vérifié'));
    }
    setFilteredProviders(result);
  }, [providers, tabValue, searchTerm, providerType]);

  useEffect(() => {
    filterProviders();
  }, [searchTerm, providerType, tabValue, providers, filterProviders]);

  useEffect(() => {
    axios.get('http://localhost:8000/api/providers-stats/')
      .then(res => {
        const allProviders = res.data.fournisseurs || [];
        setProviders(allProviders);
        setFilteredProviders(allProviders);
        setTotalRevenue(res.data.total_revenue || 0);
        setIsLoading(false);
      })
      .catch(() => setIsLoading(false));
  }, []);

  // حساب إحصائيات المزودين
  const restaurantCount = providers.filter(p => p.type === 'Restaurant').length;
  const pharmacyCount = providers.filter(p => p.type === 'Pharmacie').length;
  const supermarketCount = providers.filter(p => p.type === 'Supermarché').length;

  const handleTabChange = (event, newValue) => {
    setTabValue(newValue);
  };

  const getProviderTypeIcon = (type) => {
    switch(type) {
      case 'Restaurant':
        return <RestaurantIcon className="type-icon restaurant" />;
      case 'Pharmacie':
        return <LocalPharmacyIcon className="type-icon pharmacy" />;
      case 'Supermarché':
        return <ShoppingBasketIcon className="type-icon supermarket" />;
      default:
        return null;
    }
  };

  const handleEditClick = (provider) => {
    setEditProvider(provider);
    setEditFields({
      name: provider.nom,
      phone: provider.telephone,
      email: provider.email,
      address: provider.adresse,
      horaires_ouverture: provider.horaires_ouverture || '',
      description: provider.description || '',
      logo: null,
    });
    setEditLogoPreview(null);
    setEditDialogOpen(true);
  };

  const handleEditFieldChange = (e) => {
    setEditFields({ ...editFields, [e.target.name]: e.target.value });
  };

  const handleEditSave = async () => {
    try {
      const formData = new FormData();
      formData.append('nom_commerce', editFields.name);
      formData.append('telephone', editFields.phone);
      formData.append('email', editFields.email);
      formData.append('adresse', editFields.address);
      formData.append('horaires_ouverture', editFields.horaires_ouverture || '');
      formData.append('description', editFields.description || '');
      if (editFields.logo) formData.append('logo', editFields.logo);
      // إرسال الطلب
      const res = await axios.put(`http://localhost:8000/api/providers/${editProvider.id}/update/`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      if (res.data && res.data.status === 'success') {
        setSuccessSnackbar({ open: true, message: 'Fournisseur modifié avec succès !' });
        setEditDialogOpen(false);
        // تحديث القائمة في الواجهة
        setProviders(prev => prev.map(p => p.id === editProvider.id ? { ...p, ...res.data.fournisseur } : p));
        setFilteredProviders(prev => prev.map(p => p.id === editProvider.id ? { ...p, ...res.data.fournisseur } : p));
      } else {
        setErrorSnackbar({ open: true, message: res.data.message || 'Erreur lors de la modification.' });
      }
    } catch (error) {
      setErrorSnackbar({ open: true, message: error.response?.data?.message || 'Erreur lors de la modification.' });
    }
  };

  const handleEditCancel = () => {
    setEditDialogOpen(false);
  };

  const handleAddClick = () => {
    setNewProvider({
      username: '',
      password: '',
      email: '',
      telephone: '',
      adresse: '',
      type_fournisseur: '',
      nom_commerce: '',
      description: '',
      adresse_commerce: '',
      horaires_ouverture: '',
      latitude: 18.0735, // موقع افتراضي (نواكشوط)
      longitude: -15.9582,
      logo: null,
      logo_preview: null,
      photo_profile: null,
      photo_profile_preview: null
    });
    setActiveTab(0); // إعادة تعيين التبويب النشط إلى الأول
    setAddDialogOpen(true);
  };

  const handleNewProviderChange = (e) => {
    setNewProvider({ ...newProvider, [e.target.name]: e.target.value });
  };

  const handleAddProviderSave = async () => {
    try {
      const formData = new FormData();
      // بيانات Utilisateur
      formData.append('username', newProvider.username);
      formData.append('password', newProvider.password);
      formData.append('email', newProvider.email);
      formData.append('telephone', newProvider.telephone);
      formData.append('adresse', newProvider.adresse || '');
      if (newProvider.photo_profile) formData.append('photo_profile', newProvider.photo_profile);
      // إضافة الإحداثيات
      formData.append('latitude', newProvider.latitude);
      formData.append('longitude', newProvider.longitude);
      // بيانات Fournisseur
      formData.append('type_fournisseur', newProvider.type_fournisseur);
      formData.append('nom_commerce', newProvider.nom_commerce);
      formData.append('description', newProvider.description || '');
      if (newProvider.logo) formData.append('logo', newProvider.logo);
      formData.append('adresse_commerce', newProvider.adresse_commerce || '');
      formData.append('horaires_ouverture', newProvider.horaires_ouverture || '');

      // إرسال الطلب إلى API الجديد
      const res = await axios.post('http://localhost:8000/api/create-provider/', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      if (res.data && res.data.status === 'success') {
        setAddDialogOpen(false);
        setSuccessSnackbar({ open: true, message: 'تمت إضافة المزود بنجاح!' });
      } else {
        setErrorDialog({
          open: true,
          message: res.data.message || 'خطأ غير معروف',
          status: res.status,
          url: res.config?.url || '',
          errors: res.data.errors || null,
        });
        setErrorSnackbar({ open: true, message: res.data.message || 'فشل في إضافة المزود!' });
      }
    } catch (error) {
      setErrorDialog({
        open: true,
        message: error.response?.data?.message || error.message,
        status: error.response?.status || '',
        url: error.config?.url || '',
        errors: error.response?.data?.errors || null,
      });
      setErrorSnackbar({ open: true, message: error.response?.data?.message || 'فشل في إضافة المزود!' });
    }
  };

  const handleAddProviderCancel = () => {
    setAddDialogOpen(false);
  };

  const handleDeleteProvider = async () => {
    if (!editProvider) return;
    try {
      const res = await axios.delete(`http://localhost:8000/api/providers/${editProvider.id}/delete/`);
      if (res.data && res.data.status === 'success') {
        setProviders(prev => prev.filter(p => p.id !== editProvider.id));
        setFilteredProviders(prev => prev.filter(p => p.id !== editProvider.id));
        setEditDialogOpen(false);
        setSuccessSnackbar({ open: true, message: 'Fournisseur et ses produits supprimés avec succès.' });
      } else {
        setErrorSnackbar({ open: true, message: res.data.message || 'Erreur lors de la suppression.' });
      }
    } catch (error) {
      setErrorSnackbar({ open: true, message: error.response?.data?.message || 'Erreur lors de la suppression.' });
    }
  };

  const handleCloseProductsDialog = () => {
    setProductsDialogOpen(false);
    setProducts([]);
    setFilteredProducts([]);
    setProductSearchTerm('');
  };

  const handleCloseAddProductDialog = () => {
    setAddProductDialogOpen(false);
    setNewProduct({
      nom: '',
      description: '',
      prix: '',
      categorie: '',
      disponible: true,
      image: null
    });
  };

  const handleCloseEditProductDialog = () => {
    setEditProductDialogOpen(false);
    setSelectedProduct(null);
  };

  const handleProductsDialogOpen = async (provider) => {
    setViewProvider(provider);
    try {
      const response = await axios.get(`http://localhost:8000/api/produits/providers/${provider.id}/products/`);
      setProducts(response.data || []);
      setFilteredProducts(response.data || []);
      setProductsDialogOpen(true);
    } catch (error) {
      console.error('Error fetching products:', error);
      setErrorSnackbar({ open: true, message: 'Erreur lors de la récupération des produits.' });
    }
  };

  const handleProductSearch = (event) => {
    const searchTerm = event.target.value.toLowerCase();
    setProductSearchTerm(searchTerm);
    if (!products) return;
    
    const filtered = products.filter(product => 
      product?.nom?.toLowerCase().includes(searchTerm) ||
      product?.description?.toLowerCase().includes(searchTerm) ||
      product?.categorie?.toLowerCase().includes(searchTerm)
    );
    setFilteredProducts(filtered);
  };

  const handleOpenAddProductDialog = () => {
    if (!viewProvider || !viewProvider.id) {
      setErrorSnackbar({ open: true, message: 'Aucun fournisseur sélectionné.' });
      return;
    }
    setAddProductDialogOpen(true);
  };

  const handleAddProduct = async () => {
    if (!newProduct.nom || !newProduct.prix) {
      setErrorSnackbar({ open: true, message: 'Veuillez remplir tous les champs obligatoires.' });
      return;
    }
    try {
      const formData = new FormData();
      Object.keys(newProduct).forEach(key => {
        if (newProduct[key] !== null && newProduct[key] !== undefined) {
          formData.append(key, newProduct[key]);
        }
      });
      // إضافة معرف المزود الحالي
      if (viewProvider && viewProvider.id) {
        formData.append('fournisseur', viewProvider.id);
      } else {
        setErrorSnackbar({ open: true, message: 'Aucun fournisseur sélectionné.' });
        return;
      }
      const response = await axios.post('http://localhost:8000/api/produits/create/', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      if (response.data) {
        setProducts(prev => [...prev, response.data]);
        setFilteredProducts(prev => [...prev, response.data]);
        handleCloseAddProductDialog();
        setSuccessSnackbar({ open: true, message: 'Produit ajouté avec succès !' });
      }
    } catch (error) {
      setErrorSnackbar({ open: true, message: error.response?.data?.message || 'Erreur lors de l\'ajout du produit.' });
    }
  };

  const handleEditProduct = async () => {
    if (!selectedProduct?.nom || !selectedProduct?.prix) {
      setErrorSnackbar({ open: true, message: 'Veuillez remplir tous les champs obligatoires.' });
      return;
    }
    try {
      const formData = new FormData();
      Object.keys(selectedProduct).forEach(key => {
        if (selectedProduct[key] !== null && selectedProduct[key] !== undefined) {
          formData.append(key, selectedProduct[key]);
        }
      });
      // إضافة معرف المزود الحالي
      if (viewProvider && viewProvider.id) {
        formData.append('fournisseur', viewProvider.id);
      } else {
        setErrorSnackbar({ open: true, message: 'Aucun fournisseur sélectionné.' });
        return;
      }
      const response = await axios.put(`http://localhost:8000/api/produits/${selectedProduct.id}/update/`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      if (response.data) {
        const updatedProducts = products.map(p => 
          p.id === selectedProduct.id ? response.data : p
        );
        setProducts(updatedProducts);
        setFilteredProducts(updatedProducts);
        handleCloseEditProductDialog();
        setSuccessSnackbar({ open: true, message: 'Produit modifié avec succès !' });
      }
    } catch (error) {
      setErrorSnackbar({ open: true, message: error.response?.data?.message || 'Erreur lors de la modification du produit.' });
    }
  };

  const handleDeleteProduct = (productId) => {
    setProductToDelete(productId);
    setDeleteDialogOpen(true);
  };

  const confirmDeleteProduct = async () => {
    if (!productToDelete) return;
    try {
      await axios.delete(`http://localhost:8000/api/produits/${productToDelete}/delete/`);
      const updatedProducts = products.filter(p => p.id !== productToDelete);
      setProducts(updatedProducts);
      setFilteredProducts(updatedProducts);
      setSuccessSnackbar({ open: true, message: 'Produit supprimé avec succès !' });
    } catch (error) {
      setErrorSnackbar({ open: true, message: error.response?.data?.message || 'Erreur lors de la suppression du produit.' });
    }
    setDeleteDialogOpen(false);
    setProductToDelete(null);
  };

  const cancelDeleteProduct = () => {
    setDeleteDialogOpen(false);
    setProductToDelete(null);
  };

  const productTableHeaders = [
    { label: 'Image', align: 'center' },
    { label: 'Nom', align: 'center' },
    { label: 'Description', align: 'center' },
    { label: 'Prix', align: 'center' },
    { label: 'Catégorie', align: 'center' },
    { label: 'Statut', align: 'center' },
    { label: 'Actions', align: 'center' },
  ];

  const handleVerifyToggle = async (provider, newStatus) => {
    try {
      const res = await axios.patch(`http://localhost:8000/api/providers/${provider.id}/verify/`, { is_active: newStatus });
      if (res.data && res.data.status === 'success') {
        setEditProvider({ ...provider, statut: newStatus ? 'Vérifié' : 'Non vérifié' });
        setProviders(prev => prev.map(p => p.id === provider.id ? { ...p, statut: newStatus ? 'Vérifié' : 'Non vérifié' } : p));
        setFilteredProviders(prev => prev.map(p => p.id === provider.id ? { ...p, statut: newStatus ? 'Vérifié' : 'Non vérifié' } : p));
        setSuccessSnackbar({ open: true, message: newStatus ? 'Fournisseur vérifié !' : 'Vérification révoquée !' });
      } else {
        setErrorSnackbar({ open: true, message: res.data.message || 'Erreur lors du changement de statut.' });
      }
    } catch (error) {
      setErrorSnackbar({ open: true, message: error.response?.data?.message || 'Erreur lors du changement de statut.' });
    }
  };

  // دالة تصدير Excel
  const exportToExcel = () => {
    const ws = XLSX.utils.json_to_sheet(printProviders.map(provider => ({
      'ID': provider.id,
      'Nom': provider.nom,
      'Type': provider.type,
      'E-mail': provider.email,
      'Téléphone': provider.telephone,
      'Adresse': provider.adresse,
      'Commandes': provider.commandes,
      'Revenu': provider.revenu,
      'Produits': provider.produits,
      'Statut': provider.statut,
      'Date d\'inscription': provider.date_inscription,
    })));
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Fournisseurs');
    XLSX.writeFile(wb, 'liste_fournisseurs.xlsx');
  };

  // دالة تصدير Word
  const exportToWord = () => {
    const table = document.getElementById('print-preview-table-provider');
    if (!table) return;
    const html = `<html><head><meta charset='utf-8'></head><body>${table.innerHTML}</body></html>`;
    const converted = htmlDocx.asBlob(html);
    const link = document.createElement('a');
    link.href = URL.createObjectURL(converted);
    link.download = 'liste_fournisseurs.docx';
    link.click();
  };

  // تعديل دالة زر الطباعة لجلب التفاصيل قبل الفتح
  const handlePrintClick = async () => {
    // جلب تفاصيل الطلبات والمنتجات لكل مزود
    const providersWithDetails = await Promise.all(filteredProviders.map(async (provider) => {
      let commandes = [];
      let products = [];
      try {
        // جلب الطلبات
        const cmdRes = await axios.get(`http://localhost:8000/api/commandes/providers/${provider.id}/orders/`);
        if (Array.isArray(cmdRes.data.orders)) {
          commandes = cmdRes.data.orders;
        } else if (Array.isArray(cmdRes.data.commandes)) {
          commandes = cmdRes.data.commandes;
        } else if (Array.isArray(cmdRes.data)) {
          commandes = cmdRes.data;
        }
      } catch (e) { commandes = []; }
      try {
        // جلب المنتجات
        const prodRes = await axios.get(`http://localhost:8000/api/produits/providers/${provider.id}/products/`);
        if (Array.isArray(prodRes.data)) {
          products = prodRes.data;
        } else if (Array.isArray(prodRes.data.products)) {
          products = prodRes.data.products;
        }
      } catch (e) { products = []; }
      return { ...provider, commandes, products };
    }));
    setPrintProviders(providersWithDetails);
    setOpenPrintDialog(true);
  };

  if (isLoading) {
    return <div className="loading">Chargement...</div>;
  }

  return (
    <div className="provider-management-page">
      <h1 className="page-title">Gestion des fournisseurs</h1>
      
      {/* زر إضافة مزود جديد بالفرنسية مع تحسين التجاوب */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 16, flexWrap: 'wrap', gap: 8 }}>
        <Button
          variant="outlined"
          color="secondary"
          startIcon={<PrintIcon />}
          sx={{ borderRadius: 2, fontWeight: 700, boxShadow: 1, minWidth: 48 }}
          onClick={handlePrintClick}
        >
          Imprimer la liste
        </Button>
        <Button 
          variant="contained" 
          color="primary" 
          startIcon={<AddIcon />} 
          onClick={handleAddClick}
          style={{ minWidth: 180, fontSize: 16 }}
        >
          Ajouter un fournisseur
        </Button>
      </div>
      
      {/* بطاقات الإحصائيات */}
      <Grid container spacing={2} className="stats-container">
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon provider-icon">
                <RestaurantIcon />
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">Restaurants</Typography>
                <Typography variant="h4" component="p">{restaurantCount}</Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon pharmacy-icon">
                <LocalPharmacyIcon />
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">Pharmacies</Typography>
                <Typography variant="h4" component="p">{pharmacyCount}</Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon supermarket-icon">
                <ShoppingBasketIcon />
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">Supermarchés</Typography>
                <Typography variant="h4" component="p">{supermarketCount}</Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <Card className="stat-card">
            <CardContent>
              <div className="stat-icon revenue-icon">
                <Typography variant="h6" component="div" className="currency">MRU</Typography>
              </div>
              <div className="stat-info">
                <Typography variant="h6" component="h2">Revenu total</Typography>
                <Typography variant="h4" component="p">{(totalRevenue || 0).toLocaleString()}</Typography>
              </div>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
      
      {/* التابات والفلاتر */}
      <div className="filters-section">
        <div className="tabs-container">
          <Tabs value={tabValue} onChange={handleTabChange} variant="scrollable" scrollButtons="auto">
            <Tab label="Tous" />
            <Tab label="Restaurants" />
            <Tab label="Pharmacies" />
            <Tab label="Supermarchés" />
          </Tabs>
        </div>
        
        <div className="filters-container">
          <div className="search-box">
            <SearchIcon />
            <TextField
              variant="outlined"
              size="small"
              placeholder="Recherche par nom, e-mail ou téléphone"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          
          <div className="filter-status">
            <FormControl variant="outlined" size="small">
              <InputLabel>Statut</InputLabel>
              <Select
                value={providerType}
                onChange={(e) => setProviderType(e.target.value)}
                label="Statut"
              >
                <MenuItem value="all">Tous</MenuItem>
                <MenuItem value="verified">Vérifié</MenuItem>
                <MenuItem value="unverified">Non vérifié</MenuItem>
              </Select>
            </FormControl>
          </div>
        </div>
      </div>
      
      {/* جدول المزودين */}
      <TableContainer component={Paper} className="providers-table">
        <Table aria-label="Tableau des fournisseurs">
          <TableHead>
            <TableRow>
              <TableCell>ID Fournisseur</TableCell>
              <TableCell>Nom</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>E-mail</TableCell>
              <TableCell>Téléphone</TableCell>
              <TableCell>Adresse</TableCell>
              <TableCell>Commandes</TableCell>
              <TableCell>Revenu</TableCell>
              <TableCell>Note</TableCell>
              <TableCell>Produits</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Date d'inscription</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredProviders.map((provider) => (
              <TableRow key={provider.id}>
                <TableCell>{provider.id}</TableCell>
                <TableCell>{provider.nom}</TableCell>
                <TableCell>
                  <div className="provider-type">
                    {getProviderTypeIcon(provider.type)}
                    <span style={{ marginLeft: 6 }}>{provider.type}</span>
                  </div>
                </TableCell>
                <TableCell>{provider.email}</TableCell>
                <TableCell>{provider.telephone}</TableCell>
                <TableCell>{provider.adresse}</TableCell>
                <TableCell>{Array.isArray(provider.commandes) ? provider.commandes.length : (typeof provider.commandes === 'number' ? provider.commandes : 0)}</TableCell>
                <TableCell>{(provider.revenu || 0).toLocaleString()}</TableCell>
                <TableCell className="rating-cell">
                  <span className="rating">{provider.note}</span>
                </TableCell>
                <TableCell>{provider.produits}</TableCell>
                <TableCell>
                  <Chip 
                    label={provider.statut}
                    color={provider.statut === 'Vérifié' ? 'primary' : 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>{provider.date_inscription}</TableCell>
                <TableCell>
                  <div className="action-buttons">
                    <IconButton size="small" title="Voir les informations" onClick={() => { setViewProvider(provider); setViewDialogOpen(true); }}>
                      <VisibilityIcon fontSize="small" />
                    </IconButton>
                    <IconButton size="small" title="Voir les produits" onClick={() => handleProductsDialogOpen(provider)}>
                      <ShoppingBasketIcon fontSize="small" />
                    </IconButton>
                    <IconButton size="small" title="Modifier" onClick={() => handleEditClick(provider)}>
                      <EditIcon fontSize="small" />
                    </IconButton>
                  </div>
                </TableCell>
              </TableRow>
            ))}
            {filteredProviders.length === 0 && (
              <TableRow>
                <TableCell colSpan={13} align="center">
                  Aucun résultat correspondant aux critères de recherche
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* نافذة حوار التعديل الجديدة */}
      <Dialog open={editDialogOpen} onClose={handleEditCancel} maxWidth="xs" fullWidth>
        <Card sx={{ p: { xs: 2, sm: 4 }, borderRadius: 4, boxShadow: 8, bgcolor: '#f8fafc' }}>
          <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1, pb: 1, bgcolor: '#f5f7fa', borderRadius: 2 }}>
            <EditIcon color="primary" sx={{ fontSize: 30 }} />
            <span style={{ fontWeight: 800, fontSize: 22, color: '#1976d2' }}>Modifier les informations du fournisseur</span>
          </DialogTitle>
          <Divider sx={{ mb: 2 }} />
          <DialogContent sx={{ maxHeight: 420, overflowY: 'auto' }}>
            <TextField
              margin="dense"
              label="Nom du fournisseur"
              name="name"
              value={editFields.name}
              onChange={handleEditFieldChange}
              fullWidth
              InputLabelProps={{ shrink: true }}
            />
            <TextField
              margin="dense"
              label="Numéro de téléphone"
              name="phone"
              value={editFields.phone}
              onChange={handleEditFieldChange}
              fullWidth
              InputLabelProps={{ shrink: true }}
            />
            <TextField
              margin="dense"
              label="E-mail"
              name="email"
              value={editFields.email}
              onChange={handleEditFieldChange}
              fullWidth
              InputLabelProps={{ shrink: true }}
            />
            <TextField
              margin="dense"
              label="Adresse"
              name="address"
              value={editFields.address}
              onChange={handleEditFieldChange}
              fullWidth
              InputLabelProps={{ shrink: true }}
            />
            <TextField
              margin="dense"
              label="Horaires d'ouverture"
              name="horaires_ouverture"
              value={editFields.horaires_ouverture || ''}
              onChange={handleEditFieldChange}
              fullWidth
              InputLabelProps={{ shrink: true }}
            />
            <TextField
              margin="dense"
              label="Description"
              name="description"
              value={editFields.description || ''}
              onChange={handleEditFieldChange}
              fullWidth
              multiline
              rows={2}
              InputLabelProps={{ shrink: true }}
            />
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mt: 2 }}>
              <Button variant="outlined" component="label" startIcon={<AddAPhotoIcon />} sx={{ borderRadius: '50px', px: 3 }}>
                Logo
                <input type="file" accept="image/*" hidden onChange={e => {
                  setEditFields({ ...editFields, logo: e.target.files[0] });
                  if (e.target.files[0]) {
                    const reader = new FileReader();
                    reader.onload = ev => setEditLogoPreview(ev.target.result);
                    reader.readAsDataURL(e.target.files[0]);
                  }
                }} />
              </Button>
              {(editLogoPreview || (editProvider && editProvider.logo)) && (
                <img src={editLogoPreview || editProvider.logo} alt="Aperçu logo" style={{ maxWidth: 60, maxHeight: 60, borderRadius: 8, boxShadow: '0 2px 8px #bbb' }} />
              )}
            </Box>
            <Box sx={{ display: 'flex', gap: 2, mt: 3 }}>
              <Button
                variant="outlined"
                color="error"
                onClick={handleDeleteProvider}
                sx={{ fontWeight: 700, borderRadius: 3 }}
              >
                Supprimer le fournisseur
              </Button>
              {editProvider && editProvider.statut === 'Vérifié' && (
                <Button
                  variant="contained"
                  color="warning"
                  onClick={() => handleVerifyToggle(editProvider, false)}
                  sx={{ fontWeight: 700, borderRadius: 3 }}
                >
                  Révoquer la vérification
                </Button>
              )}
              {editProvider && editProvider.statut === 'Non vérifié' && (
                <Button
                  variant="contained"
                  color="success"
                  onClick={() => handleVerifyToggle(editProvider, true)}
                  sx={{ fontWeight: 700, borderRadius: 3 }}
                >
                  Déverrouiller la vérification
                </Button>
              )}
            </Box>
          </DialogContent>
          <Divider sx={{ my: 2 }} />
          <DialogActions>
            <Button onClick={handleEditCancel} color="primary" sx={{ fontWeight: 700 }}>Annuler</Button>
            <Button onClick={handleEditSave} color="success" variant="contained" sx={{ fontWeight: 700 }}>Enregistrer</Button>
          </DialogActions>
        </Card>
      </Dialog>

      {/* نافذة حوار إضافة مزود جديد - تصميم محسن */}
      <Dialog 
        open={addDialogOpen} 
        onClose={handleAddProviderCancel} 
        maxWidth="md" 
        fullWidth
        PaperProps={{
          sx: {
            borderRadius: 3,
            overflow: 'hidden',
            bgcolor: 'background.paper',
            boxShadow: '0 8px 40px rgba(0,0,0,0.12)'
          }
        }}
      >
        <Box sx={{ 
          display: 'flex', 
          flexDirection: { xs: 'column', md: 'row' },
          height: { xs: 'auto', md: '80vh' }
        }}>
          {/* القسم الجانبي */}
          <Box sx={{ 
            width: { xs: '100%', md: '280px' },
            bgcolor: 'primary.main',
            color: 'white',
            p: 3,
            display: 'flex',
            flexDirection: 'column'
          }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
              <Typography variant="h5" fontWeight="bold">Ajouter un fournisseur</Typography>
              <IconButton 
                onClick={handleAddProviderCancel} 
                sx={{ color: 'white' }}
                aria-label="Fermer"
              >
                <CloseIcon />
              </IconButton>
            </Box>
            
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', my: 3 }}>
              <Avatar
                src={newProvider.photo_profile_preview}
                sx={{ 
                  width: 120, 
                  height: 120, 
                  mb: 1, 
                  bgcolor: 'rgba(255,255,255,0.2)',
                  boxShadow: '0 4px 20px rgba(0,0,0,0.2)',
                  border: '4px solid rgba(255,255,255,0.3)'
                }}
              >
                {!newProvider.photo_profile_preview && <StoreIcon sx={{ fontSize: 60 }} />}
              </Avatar>
              <IconButton
                component="label"
                sx={{ 
                  position: 'relative', 
                  top: -30, 
                  left: 40, 
                  bgcolor: 'secondary.main',
                  boxShadow: 2,
                  '&:hover': { bgcolor: 'secondary.dark' } 
                }}
                size="small"
              >
                <AddAPhotoIcon sx={{ color: 'white' }} />
                <input type="file" accept="image/*" hidden onChange={e => {
                  setNewProvider({ ...newProvider, photo_profile: e.target.files[0] });
                  if (e.target.files[0]) {
                    const reader = new FileReader();
                    reader.onload = ev => setNewProvider(prev => ({ ...prev, photo_profile_preview: ev.target.result }));
                    reader.readAsDataURL(e.target.files[0]);
                  }
                }} />
              </IconButton>
              <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.7)', textAlign: 'center', mt: -2 }}>
                Photo du fournisseur
              </Typography>
            </Box>

            <Box sx={{ flexGrow: 1 }}>
              <Typography variant="body1" sx={{ mb: 2, fontWeight: 'medium' }}>
                Informations du fournisseur:
            </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <PersonIcon sx={{ mr: 1, fontSize: 20 }} />
                <Typography variant="body2" noWrap>
                  {newProvider.username || 'Nom d\'utilisateur'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <EmailIcon sx={{ mr: 1, fontSize: 20 }} />
                <Typography variant="body2" noWrap>
                  {newProvider.email || 'Email'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <PhoneIcon sx={{ mr: 1, fontSize: 20 }} />
                <Typography variant="body2" noWrap>
                  {newProvider.telephone || 'Téléphone'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <BusinessIcon sx={{ mr: 1, fontSize: 20 }} />
                <Typography variant="body2" noWrap>
                  {newProvider.nom_commerce || 'Nom du commerce'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <CategoryIcon sx={{ mr: 1, fontSize: 20 }} />
                <Typography variant="body2" noWrap>
                  {newProvider.type_fournisseur || 'Type de fournisseur'}
                </Typography>
              </Box>
            </Box>

            <Box sx={{ mt: 'auto', pt: 3 }}>
              <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.7)', mb: 1 }}>
                * Tous les champs marqués d'un astérisque sont obligatoires
              </Typography>
              <Button 
                variant="contained" 
                fullWidth 
                onClick={handleAddProviderSave}
                startIcon={<SaveIcon />}
                sx={{ 
                  bgcolor: 'white', 
                  color: 'primary.main',
                  fontWeight: 'bold',
                  '&:hover': { bgcolor: 'rgba(255,255,255,0.9)' }
                }}
              >
                Enregistrer
              </Button>
              <Button 
                variant="outlined" 
                fullWidth 
                onClick={handleAddProviderCancel}
                startIcon={<CancelIcon />}
                sx={{ 
                  mt: 1, 
                  borderColor: 'rgba(255,255,255,0.5)', 
                  color: 'white',
                  '&:hover': { borderColor: 'white', bgcolor: 'rgba(255,255,255,0.1)' }
                }}
              >
                Annuler
              </Button>
            </Box>
          </Box>

          {/* القسم الرئيسي للنموذج */}
          <Box sx={{ 
            flexGrow: 1,
            p: 0,
            overflowY: 'auto',
            display: 'flex',
            flexDirection: 'column'
          }}>
            <Box sx={{ 
              bgcolor: 'rgba(25, 118, 210, 0.05)',
              borderBottom: '1px solid rgba(0,0,0,0.08)',
              p: 2
            }}>
              <Typography variant="h6" fontWeight="bold" color="primary">
                Données du fournisseur
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Saisissez les informations du nouveau fournisseur avec précision
              </Typography>
            </Box>

            <Box sx={{ p: 3, flexGrow: 1 }}>
              <Tabs 
                value={activeTab} 
                onChange={(e, newValue) => setActiveTab(newValue)}
                sx={{ mb: 3, borderBottom: 1, borderColor: 'divider' }}
                variant="scrollable"
                scrollButtons="auto"
              >
                <Tab label="Informations de base" icon={<PersonIcon />} iconPosition="start" />
                <Tab label="Informations du commerce" icon={<StoreIcon />} iconPosition="start" />
                <Tab label="Localisation" icon={<MapIcon />} iconPosition="start" />
              </Tabs>

              {activeTab === 0 && (
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6}>
                    <TextField 
                      label="Nom d'utilisateur *" 
                      name="username" 
                      value={newProvider.username} 
                      onChange={handleNewProviderChange} 
                      fullWidth 
                      required
                      InputProps={{
                        startAdornment: <PersonIcon color="action" sx={{ mr: 1 }} />
                      }}
                    />
              </Grid>
              <Grid item xs={12} sm={6}>
                    <TextField 
                      label="Mot de passe *" 
                      name="password" 
                      type="password" 
                      value={newProvider.password} 
                      onChange={handleNewProviderChange} 
                      fullWidth 
                      required
                      InputProps={{
                        startAdornment: <LockIcon color="action" sx={{ mr: 1 }} />
                      }}
                    />
              </Grid>
              <Grid item xs={12} sm={6}>
                    <TextField 
                      label="E-mail *" 
                      name="email" 
                      value={newProvider.email} 
                      onChange={handleNewProviderChange} 
                      fullWidth 
                      required
                      InputProps={{
                        startAdornment: <EmailIcon color="action" sx={{ mr: 1 }} />
                      }}
                    />
              </Grid>
              <Grid item xs={12} sm={6}>
                    <TextField 
                      label="Numéro de téléphone *" 
                      name="telephone" 
                      value={newProvider.telephone} 
                      onChange={handleNewProviderChange} 
                      fullWidth 
                      required
                      InputProps={{
                        startAdornment: <PhoneIcon color="action" sx={{ mr: 1 }} />
                      }}
                    />
              </Grid>
                  <Grid item xs={12}>
                    <TextField 
                      label="Adresse" 
                      name="adresse" 
                      value={newProvider.adresse} 
                      onChange={handleNewProviderChange} 
                      fullWidth
                      InputProps={{
                        startAdornment: <LocationOnIcon color="action" sx={{ mr: 1 }} />
                      }}
                    />
                  </Grid>
                </Grid>
              )}

              {activeTab === 1 && (
                <Grid container spacing={3}>
                  <Grid item xs={12} sm={6}>
                    <FormControl fullWidth required>
                      <InputLabel>Type de fournisseur *</InputLabel>
                    <Select
                      name="type_fournisseur"
                      value={newProvider.type_fournisseur}
                      onChange={handleNewProviderChange}
                      label="Type de fournisseur *"
                        startAdornment={<CategoryIcon color="action" sx={{ mr: 1 }} />}
                    >
                      <MenuItem value="Restaurant">Restaurant</MenuItem>
                      <MenuItem value="Pharmacie">Pharmacie</MenuItem>
                      <MenuItem value="Supermarché">Supermarché</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
                  <Grid item xs={12} sm={6}>
                  <TextField
                    label="Nom du commerce *"
                    name="nom_commerce"
                    value={newProvider.nom_commerce}
                    onChange={handleNewProviderChange}
                    fullWidth
                    required
                      InputProps={{
                        startAdornment: <StoreIcon color="action" sx={{ mr: 1 }} />
                      }}
                  />
                </Grid>
              <Grid item xs={12}>
                    <TextField 
                      label="Description" 
                      name="description" 
                      value={newProvider.description} 
                      onChange={handleNewProviderChange} 
                      fullWidth 
                      multiline 
                      rows={3}
                      InputProps={{
                        startAdornment: <DescriptionIcon color="action" sx={{ mr: 1, alignSelf: 'flex-start', mt: 1 }} />
                      }}
                    />
              </Grid>
              <Grid item xs={12}>
                    <TextField 
                      label="Heures d'ouverture" 
                      name="horaires_ouverture" 
                      value={newProvider.horaires_ouverture} 
                      onChange={handleNewProviderChange} 
                      fullWidth
                      placeholder="Ex: Lundi à Vendredi: 9:00 - 18:00"
                      InputProps={{
                        startAdornment: <ScheduleIcon color="action" sx={{ mr: 1 }} />
                      }}
                    />
              </Grid>
              <Grid item xs={12}>
                    <Box sx={{ 
                      display: 'flex', 
                      alignItems: 'center', 
                      gap: 2,
                      p: 2,
                      border: '1px dashed',
                      borderColor: 'primary.main',
                      borderRadius: 2,
                      bgcolor: 'rgba(25, 118, 210, 0.04)'
                    }}>
                      <Button 
                        variant="outlined" 
                        component="label" 
                        startIcon={<AddAPhotoIcon />} 
                        sx={{ borderRadius: '50px', px: 3 }}
                      >
                        Logo
                    <input type="file" accept="image/*,application/pdf" hidden onChange={e => {
                      setNewProvider({ ...newProvider, logo: e.target.files[0] });
                      if (e.target.files[0]) {
                        if (e.target.files[0].type === 'application/pdf') {
                          setNewProvider(prev => ({ ...prev, logo_preview: 'pdf' }));
                        } else {
                          const reader = new FileReader();
                          reader.onload = ev => setNewProvider(prev => ({ ...prev, logo_preview: ev.target.result }));
                          reader.readAsDataURL(e.target.files[0]);
                        }
                      }
                    }} />
                  </Button>
                  {newProvider.logo_preview && (
                        <Box sx={{ position: 'relative' }}>
                          {newProvider.logo_preview === 'pdf' ? (
                            <Box sx={{ 
                              width: 80, 
                              height: 80, 
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              bgcolor: 'grey.200',
                              borderRadius: 1
                            }}>
                              <PictureAsPdfIcon sx={{ fontSize: 40, color: 'error.main' }} />
                      </Box>
                    ) : (
                            <img 
                              src={newProvider.logo_preview} 
                              alt="Logo du commerce" 
                              style={{ 
                                maxWidth: 80, 
                                maxHeight: 80, 
                                borderRadius: 8,
                                boxShadow: '0 2px 8px rgba(0,0,0,0.2)'
                              }} 
                            />
                          )}
                          <IconButton 
                            size="small"
                            sx={{ 
                              position: 'absolute',
                              top: -8,
                              right: -8,
                              bgcolor: 'error.main',
                              color: 'white',
                              '&:hover': { bgcolor: 'error.dark' }
                            }}
                            onClick={() => setNewProvider(prev => ({ ...prev, logo: null, logo_preview: null }))}
                          >
                            <CloseIcon fontSize="small" />
                          </IconButton>
                        </Box>
                  )}
                </Box>
              </Grid>
                </Grid>
              )}

              {activeTab === 2 && (
                <Box sx={{ height: 400, display: 'flex', flexDirection: 'column' }}>
                  <Typography variant="subtitle1" sx={{ mb: 2 }}>
                    <MapIcon sx={{ verticalAlign: 'middle', mr: 1 }} />
                    Sélectionnez l'emplacement du commerce (cliquez sur la carte)
                  </Typography>
                  
                  <Box sx={{ 
                    flexGrow: 1, 
                    border: '1px solid rgba(0,0,0,0.12)', 
                    borderRadius: 1,
                    overflow: 'hidden',
                    position: 'relative',
                    height: 300
                  }}>
                    <MapContainer 
                      center={[newProvider.latitude, newProvider.longitude]} 
                      zoom={13} 
                      style={{ height: '100%', width: '100%' }}
                      ref={mapRef}
                    >
                      <TileLayer
                        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                      />
                      <LocationMarker 
                        position={[newProvider.latitude, newProvider.longitude]}
                        setPosition={(pos) => {
                          setNewProvider({
                            ...newProvider,
                            latitude: pos[0],
                            longitude: pos[1]
                          });
                        }}
                      />
                    </MapContainer>
                    <Box sx={{
                      position: 'absolute',
                      bottom: 10,
                      right: 10,
                      zIndex: 1000,
                      bgcolor: 'background.paper',
                      p: 1,
                      borderRadius: 1,
                      boxShadow: 2
                    }}>
                      <Button 
                        size="small" 
                        variant="contained" 
                        color="primary"
                        startIcon={<LocationOnIcon />}
                        onClick={() => {
                          if (navigator.geolocation) {
                            navigator.geolocation.getCurrentPosition(
                              (position) => {
                                const { latitude, longitude } = position.coords;
                                setNewProvider(prev => ({
                                  ...prev,
                                  latitude,
                                  longitude
                                }));
                                
                                // تحريك الخريطة إلى الموقع الحالي
                                if (mapRef.current) {
                                  mapRef.current.setView([latitude, longitude], 15);
                                }
                              },
                              (error) => {
                                console.error("Erreur de localisation:", error);
                                setErrorSnackbar({ 
                                  open: true, 
                                  message: 'Impossible d\'accéder à votre position actuelle. Veuillez sélectionner manuellement.' 
                                });
                              }
                            );
                          } else {
                            setErrorSnackbar({ 
                              open: true, 
                              message: 'Votre navigateur ne prend pas en charge la géolocalisation.' 
                            });
                          }
                        }}
                      >
                        Ma position
                      </Button>
                    </Box>
                  </Box>
                  
                  <Grid container spacing={2} sx={{ mt: 2 }}>
                    <Grid item xs={12} sm={6}>
                      <TextField 
                        label="Latitude" 
                        name="latitude" 
                        value={newProvider.latitude} 
                        onChange={(e) => {
                          const value = parseFloat(e.target.value);
                          if (!isNaN(value)) {
                            setNewProvider({...newProvider, latitude: value});
                            // تحديث موقع الخريطة عند تغيير القيمة
                            if (mapRef.current) {
                              mapRef.current.setView([value, newProvider.longitude], mapRef.current.getZoom());
                            }
                          }
                        }}
                        fullWidth
                        InputProps={{
                          startAdornment: <LocationOnIcon color="action" sx={{ mr: 1 }} />
                        }}
                      />
                    </Grid>
                    <Grid item xs={12} sm={6}>
                      <TextField 
                        label="Longitude" 
                        name="longitude" 
                        value={newProvider.longitude} 
                        onChange={(e) => {
                          const value = parseFloat(e.target.value);
                          if (!isNaN(value)) {
                            setNewProvider({...newProvider, longitude: value});
                            // تحديث موقع الخريطة عند تغيير القيمة
                            if (mapRef.current) {
                              mapRef.current.setView([newProvider.latitude, value], mapRef.current.getZoom());
                            }
                          }
                        }}
                        fullWidth
                        InputProps={{
                          startAdornment: <LocationOnIcon color="action" sx={{ mr: 1 }} />
                        }}
                      />
              </Grid>
              <Grid item xs={12}>
                      <TextField 
                        label="Adresse du commerce" 
                        name="adresse_commerce" 
                        value={newProvider.adresse_commerce} 
                        onChange={handleNewProviderChange} 
                        fullWidth
                        InputProps={{
                          startAdornment: <BusinessIcon color="action" sx={{ mr: 1 }} />
                        }}
                      />
              </Grid>
            </Grid>
            </Box>
              )}
            </Box>

            <Box sx={{ 
              p: 2, 
              borderTop: '1px solid rgba(0,0,0,0.08)',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              bgcolor: 'rgba(0,0,0,0.02)'
            }}>
              <Button 
                onClick={handleAddProviderCancel}
                startIcon={<CancelIcon />}
              >
                Annuler
              </Button>
              <Box>
                <Button 
                  onClick={() => setActiveTab(prev => Math.max(0, prev - 1))}
                  disabled={activeTab === 0}
                  sx={{ mr: 1 }}
                >
                  Précédent
                </Button>
                {activeTab < 2 ? (
                  <Button 
                    variant="contained" 
                    onClick={() => setActiveTab(prev => Math.min(2, prev + 1))}
                    endIcon={<ArrowForwardIcon />}
                  >
                    Suivant
                  </Button>
                ) : (
                  <Button 
                    variant="contained" 
                    color="success"
                    onClick={handleAddProviderSave}
                    startIcon={<CheckCircleIcon />}
                  >
                    Ajouter le fournisseur
                  </Button>
                )}
              </Box>
            </Box>
          </Box>
        </Box>
      </Dialog>

      {/* مربع حوار الخطأ */}
      <Dialog open={errorDialog.open} onClose={() => setErrorDialog({ ...errorDialog, open: false })}>
        <DialogTitle sx={{ color: 'error.main' }}>خطأ أثناء إضافة المزود</DialogTitle>
        <DialogContent>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 1 }}>
            <b>الحالة:</b> {errorDialog.status || '---'}
          </Typography>
          {errorDialog.url && (
            <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
              <b>الرابط:</b> {errorDialog.url}
            </Typography>
          )}
          <Typography variant="body2" color="error.main">
            {errorDialog.message}
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setErrorDialog({ ...errorDialog, open: false })} color="primary" variant="contained">إغلاق</Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar لنجاح الإضافة */}
      <Snackbar
        open={successSnackbar.open}
        autoHideDuration={4000}
        onClose={() => setSuccessSnackbar({ ...successSnackbar, open: false })}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          onClose={() => setSuccessSnackbar({ ...successSnackbar, open: false })}
          severity="success"
          variant="filled"
          sx={{ width: '100%', fontSize: 18, fontWeight: 700, alignItems: 'center', direction: 'ltr' }}
        >
          {successSnackbar.message || 'Opération réussie !'}
        </Alert>
      </Snackbar>

      {/* Snackbar لفشل الإضافة */}
      <Snackbar
        open={errorSnackbar.open}
        autoHideDuration={5000}
        onClose={() => setErrorSnackbar({ ...errorSnackbar, open: false })}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          onClose={() => setErrorSnackbar({ ...errorSnackbar, open: false })}
          severity="error"
          variant="filled"
          sx={{ width: '100%', fontSize: 17, fontWeight: 700, alignItems: 'center', direction: 'ltr' }}
        >
          {errorSnackbar.message || 'Une erreur est survenue !'}
        </Alert>
      </Snackbar>

      {/* Dialog لعرض معلومات المزود */}
      <Dialog open={viewDialogOpen} onClose={() => setViewDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ background: "#f5f7fa", borderBottom: "1px solid #eee", pb: 2 }}>
          <Box display="flex" alignItems="center" gap={1}>
            <VisibilityIcon color="primary" />
            <span style={{ fontWeight: 700, fontSize: 20 }}>Informations du fournisseur</span>
          </Box>
        </DialogTitle>
        <DialogContent sx={{ background: "#f8fafc" }}>
          {viewProvider && (
            <Box display="flex" flexDirection="column" alignItems="center" p={2}>
              {/* Logo */}
              <Avatar
                src={viewProvider.logo}
                alt="Logo"
                sx={{
                  width: 110,
                  height: 110,
                  mb: 2,
                  boxShadow: 4,
                  border: '4px solid #fff',
                  bgcolor: '#e3f2fd'
                }}
              />
              {/* Nom & Type */}
              <Typography variant="h4" fontWeight={900} color="#1976d2" gutterBottom sx={{ letterSpacing: 1 }}>
                {viewProvider.nom}
              </Typography>
              <Box display="flex" alignItems="center" gap={1} mb={2}>
                {getProviderTypeIcon(viewProvider.type)}
                <Typography variant="h6" fontWeight={700}>{viewProvider.type}</Typography>
                <Chip
                  label={viewProvider.statut}
                  color={viewProvider.statut === 'Vérifié' ? 'primary' : 'default'}
                  size="small"
                  sx={{ ml: 1, fontWeight: 700 }}
                />
              </Box>
              <Divider sx={{ width: "100%", my: 2 }} />
              {/* Informations */}
              <Grid container spacing={1} sx={{ width: '100%' }}>
                <Grid item xs={12}>
                  <Typography variant="body1" color="text.secondary" sx={{ mb: 1 }}>
                    <b>Description:</b> {viewProvider.description || <span style={{ color: '#aaa' }}>Aucune description</span>}
                  </Typography>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <EmailIcon fontSize="small" color="action" />
                    <Typography variant="body2"><b>Email:</b> {viewProvider.email}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <PhoneIcon fontSize="small" color="action" />
                    <Typography variant="body2"><b>Téléphone:</b> {viewProvider.telephone}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <LocationOnIcon fontSize="small" color="action" />
                    <Typography variant="body2"><b>Adresse:</b> {viewProvider.adresse}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <AccessTimeIcon fontSize="small" color="action" />
                    <Typography variant="body2"><b>Horaires:</b> {viewProvider.horaires_ouverture || <span style={{ color: '#aaa' }}>Non renseigné</span>}</Typography>
                  </Box>
                </Grid>
              </Grid>
              <Divider sx={{ width: "100%", my: 2 }} />
              <Box display="flex" flexWrap="wrap" justifyContent="center" gap={3} width="100%" mb={2}>
                <Typography variant="body1"><b>Commandes:</b> {viewProvider.commandes}</Typography>
                <Typography variant="body1"><b>Revenu:</b> <span style={{ color: '#388e3c', fontWeight: 700 }}>{viewProvider.revenu}</span></Typography>
                <Typography variant="body1"><b>Produits:</b> {viewProvider.produits}</Typography>
                <Typography variant="body1"><b>Note:</b> {viewProvider.note}</Typography>
              </Box>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                <b>Date d'inscription:</b> {viewProvider.date_inscription}
              </Typography>
            </Box>
          )}
        </DialogContent>
        <DialogActions sx={{ background: "#f5f7fa", borderTop: "1px solid #eee" }}>
          <Button onClick={() => setViewDialogOpen(false)} color="primary" variant="contained" sx={{ fontWeight: 700 }}>FERMER</Button>
        </DialogActions>
      </Dialog>

      {/* تحديث Dialog عرض المنتجات */}
      <Dialog 
        open={productsDialogOpen} 
        onClose={handleCloseProductsDialog} 
        maxWidth="lg" 
        fullWidth
      >
        <DialogTitle sx={{ background: "#f5f7fa", borderBottom: "1px solid #eee", pb: 2 }}>
          <Box display="flex" alignItems="center" justifyContent="space-between">
            <Box display="flex" alignItems="center" gap={1}>
              <ShoppingBasketIcon color="primary" />
              <span style={{ fontWeight: 700, fontSize: 22 }}>Produits du fournisseur</span>
            </Box>
            <Button
              variant="contained"
              color="primary"
              startIcon={<AddCircleIcon />}
              onClick={handleOpenAddProductDialog}
              sx={{ fontWeight: 700, fontSize: 16 }}
            >
              Ajouter un produit
            </Button>
          </Box>
        </DialogTitle>
        <DialogContent sx={{ background: "#f8fafc", p: 3 }}>
          <Box sx={{ mb: 3 }}>
            <TextField
              fullWidth
              variant="outlined"
              placeholder="Rechercher un produit..."
              value={productSearchTerm}
              onChange={handleProductSearch}
              InputProps={{
                startAdornment: <SearchIcon sx={{ color: 'action.active', mr: 1 }} />,
              }}
            />
          </Box>
          <TableContainer component={Paper} sx={{ maxHeight: 440, borderRadius: 3, boxShadow: 2 }}>
            <Table stickyHeader>
              <TableHead>
                <TableRow>
                  {productTableHeaders.map((header, idx) => (
                    <TableCell key={idx} align={header.align} sx={{ fontWeight: 800, fontSize: 17, background: '#f5f7fa', color: '#1976d2' }}>{header.label}</TableCell>
                  ))}
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredProducts.map((product) => (
                  <TableRow key={product.id} hover>
                    <TableCell align="center">
                      <Avatar
                        src={product.image}
                        alt={product.nom}
                        sx={{ width: 44, height: 44, margin: 'auto', border: '2px solid #e3e3e3' }}
                      />
                    </TableCell>
                    <TableCell align="center">{product.nom}</TableCell>
                    <TableCell align="center">{product.description}</TableCell>
                    <TableCell align="center">{parseFloat(product.prix).toLocaleString()}</TableCell>
                    <TableCell align="center">{product.categorie || '-'}</TableCell>
                    <TableCell align="center">
                      <Chip
                        label={product.disponible ? 'Disponible' : 'Indisponible'}
                        color={product.disponible ? 'success' : 'error'}
                        size="small"
                        sx={{ fontWeight: 700 }}
                      />
                    </TableCell>
                    <TableCell align="center">
                      <Box display="flex" gap={1} justifyContent="center">
                        <IconButton
                          size="small"
                          title="Modifier"
                          onClick={() => {
                            setSelectedProduct(product);
                            setEditProductDialogOpen(true);
                          }}
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                        <IconButton
                          size="small"
                          color="error"
                          title="Supprimer"
                          onClick={() => handleDeleteProduct(product.id)}
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Box>
                    </TableCell>
                  </TableRow>
                ))}
                {filteredProducts.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={7} align="center" sx={{ color: '#888', fontWeight: 700, fontSize: 18 }}>
                      Aucun produit trouvé.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </DialogContent>
        <DialogActions sx={{ background: "#f5f7fa", borderTop: "1px solid #eee" }}>
          <Button onClick={handleCloseProductsDialog} color="primary" variant="contained" sx={{ fontWeight: 700, fontSize: 16 }}>
            Fermer
          </Button>
        </DialogActions>
      </Dialog>

      {/* نافذة إضافة منتج جديد بتصميم عصري */}
      <Dialog 
        open={addProductDialogOpen} 
        onClose={handleCloseAddProductDialog} 
        maxWidth="md" 
        fullWidth
        PaperProps={{
          sx: {
            borderRadius: 3,
            overflow: 'hidden',
            bgcolor: 'background.paper',
            boxShadow: '0 8px 40px rgba(0,0,0,0.12)'
          }
        }}
      >
        <Box sx={{ 
          display: 'flex', 
          flexDirection: { xs: 'column', md: 'row' },
          height: { xs: 'auto', md: '70vh' }
        }}>
          {/* القسم الجانبي */}
          <Box sx={{ 
            width: { xs: '100%', md: '280px' },
            bgcolor: 'primary.main',
            color: 'white',
            p: 3,
            display: 'flex',
            flexDirection: 'column'
          }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
              <Typography variant="h5" fontWeight="bold">Ajouter un produit</Typography>
              <IconButton 
                onClick={handleCloseAddProductDialog} 
                sx={{ color: 'white' }}
                aria-label="Fermer"
              >
                <CloseIcon />
              </IconButton>
            </Box>
            
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', my: 3 }}>
              <Avatar
                src={newProduct.image ? URL.createObjectURL(newProduct.image) : undefined}
                sx={{ 
                  width: 120, 
                  height: 120, 
                  mb: 1, 
                  bgcolor: 'rgba(255,255,255,0.2)',
                  boxShadow: '0 4px 20px rgba(0,0,0,0.2)',
                  border: '4px solid rgba(255,255,255,0.3)'
                }}
              >
                {!newProduct.image && <AddAPhotoIcon sx={{ fontSize: 60 }} />}
              </Avatar>
              <IconButton
                component="label"
                sx={{ 
                  position: 'relative', 
                  top: -30, 
                  left: 40, 
                  bgcolor: 'secondary.main',
                  boxShadow: 2,
                  '&:hover': { bgcolor: 'secondary.dark' } 
                }}
                size="small"
              >
                <AddAPhotoIcon sx={{ color: 'white' }} />
                <input type="file" accept="image/*" hidden onChange={e => {
                  setNewProduct({ ...newProduct, image: e.target.files[0] });
                }} />
              </IconButton>
              <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.7)', textAlign: 'center', mt: -2 }}>
                Photo du produit
              </Typography>
            </Box>

            <Box sx={{ flexGrow: 1 }}>
              <Typography variant="body1" sx={{ mb: 2, fontWeight: 'medium' }}>
                Informations du produit:
            </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <ShoppingBasketIcon sx={{ mr: 1, fontSize: 20 }} />
                <Typography variant="body2" noWrap>
                  {newProduct.nom || 'Nom du produit'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <CategoryIcon sx={{ mr: 1, fontSize: 20 }} />
                <Typography variant="body2" noWrap>
                  {newProduct.categorie || 'Catégorie'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <AttachMoneyIcon sx={{ mr: 1, fontSize: 20 }} />
                <Typography variant="body2" noWrap>
                  {newProduct.prix || 'Prix'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <DescriptionIcon sx={{ mr: 1, fontSize: 20 }} />
                <Typography variant="body2" noWrap>
                  {newProduct.description || 'Description'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <CheckCircleIcon sx={{ mr: 1, fontSize: 20, color: newProduct.disponible ? 'lightgreen' : 'grey.500' }} />
                <Typography variant="body2" noWrap>
                  {newProduct.disponible ? 'Disponible' : 'Indisponible'}
                </Typography>
              </Box>
            </Box>

            <Box sx={{ mt: 'auto', pt: 3 }}>
              <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.7)', mb: 1 }}>
                * Tous les champs marqués d'un astérisque sont obligatoires
              </Typography>
              <Button 
                variant="contained" 
                fullWidth 
                onClick={handleAddProduct}
                startIcon={<SaveIcon />}
                sx={{ 
                  bgcolor: 'white', 
                  color: 'primary.main',
                  fontWeight: 'bold',
                  '&:hover': { bgcolor: 'rgba(255,255,255,0.9)' }
                }}
              >
                Enregistrer
              </Button>
              <Button 
                variant="outlined" 
                fullWidth 
                onClick={handleCloseAddProductDialog}
                startIcon={<CancelIcon />}
                sx={{ 
                  mt: 1, 
                  borderColor: 'rgba(255,255,255,0.5)', 
                  color: 'white',
                  '&:hover': { borderColor: 'white', bgcolor: 'rgba(255,255,255,0.1)' }
                }}
              >
                Annuler
              </Button>
            </Box>
          </Box>

          {/* القسم الرئيسي للنموذج */}
          <Box sx={{ 
            flexGrow: 1,
            p: 0,
            overflowY: 'auto',
            display: 'flex',
            flexDirection: 'column'
          }}>
            <Box sx={{ 
              bgcolor: 'rgba(25, 118, 210, 0.05)',
              borderBottom: '1px solid rgba(0,0,0,0.08)',
              p: 2
            }}>
              <Typography variant="h6" fontWeight="bold" color="primary">
                Données du produit
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Saisissez les informations du nouveau produit avec précision
              </Typography>
            </Box>

            <Box sx={{ p: 3, flexGrow: 1 }}>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6}>
                  <TextField 
                    label="Nom du produit *" 
                    value={newProduct.nom} 
                    onChange={e => setNewProduct({ ...newProduct, nom: e.target.value })} 
                    fullWidth 
                    required
                    InputProps={{
                      startAdornment: <ShoppingBasketIcon color="action" sx={{ mr: 1 }} />
                    }}
                  />
              </Grid>
              <Grid item xs={12} sm={6}>
                  <TextField 
                    label="Catégorie" 
                    value={newProduct.categorie} 
                    onChange={e => setNewProduct({ ...newProduct, categorie: e.target.value })} 
                    fullWidth 
                    InputProps={{
                      startAdornment: <CategoryIcon color="action" sx={{ mr: 1 }} />
                    }}
                  />
              </Grid>
              <Grid item xs={12} sm={6}>
                  <TextField 
                    label="Prix *" 
                    type="number" 
                    value={newProduct.prix} 
                    onChange={e => setNewProduct({ ...newProduct, prix: e.target.value })} 
                    fullWidth 
                    required
                    InputProps={{
                      startAdornment: <AttachMoneyIcon color="action" sx={{ mr: 1 }} />
                    }}
                  />
              </Grid>
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                    control={
                      <Switch 
                        checked={newProduct.disponible} 
                        onChange={e => setNewProduct({ ...newProduct, disponible: e.target.checked })}
                        color="success"
                      />
                    }
                    label={
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <CheckCircleIcon sx={{ mr: 1, color: newProduct.disponible ? 'success.main' : 'action.disabled' }} />
                        <Typography>Disponible</Typography>
                      </Box>
                    }
                  sx={{ mt: 1 }}
                />
              </Grid>
              <Grid item xs={12}>
                  <TextField 
                    label="Description" 
                    multiline 
                    rows={4} 
                    value={newProduct.description} 
                    onChange={e => setNewProduct({ ...newProduct, description: e.target.value })} 
                    fullWidth
                    InputProps={{
                      startAdornment: <DescriptionIcon color="action" sx={{ mr: 1, alignSelf: 'flex-start', mt: 1 }} />
                    }}
                  />
              </Grid>
                <Grid item xs={12}>
                  <Box sx={{ 
                    p: 2, 
                    border: '1px dashed', 
                    borderColor: 'primary.main',
                    borderRadius: 2,
                    bgcolor: 'rgba(25, 118, 210, 0.04)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
                      Ce produit sera associé au fournisseur: <strong>{viewProvider?.nom}</strong>
                    </Typography>
                  </Box>
            </Grid>
              </Grid>
            </Box>

            <Box sx={{ 
              p: 2, 
              borderTop: '1px solid rgba(0,0,0,0.08)',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              bgcolor: 'rgba(0,0,0,0.02)'
            }}>
              <Button 
                onClick={handleCloseAddProductDialog}
                startIcon={<CancelIcon />}
              >
                Annuler
              </Button>
              <Button 
                variant="contained" 
                color="success"
                onClick={handleAddProduct}
                startIcon={<CheckCircleIcon />}
              >
                Ajouter le produit
              </Button>
            </Box>
          </Box>
        </Box>
      </Dialog>

      {/* نافذة تعديل منتج بتصميم عصري */}
      <Dialog 
        open={editProductDialogOpen} 
        onClose={handleCloseEditProductDialog} 
        maxWidth="md" 
        fullWidth
        PaperProps={{
          sx: {
            borderRadius: 3,
            overflow: 'hidden',
            bgcolor: 'background.paper',
            boxShadow: '0 8px 40px rgba(0,0,0,0.12)'
          }
        }}
      >
        <Box sx={{ 
          display: 'flex', 
          flexDirection: { xs: 'column', md: 'row' },
          height: { xs: 'auto', md: '70vh' }
        }}>
          {/* القسم الجانبي */}
          <Box sx={{ 
            width: { xs: '100%', md: '280px' },
            bgcolor: 'primary.main',
            color: 'white',
            p: 3,
            display: 'flex',
            flexDirection: 'column'
          }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
              <Typography variant="h5" fontWeight="bold">Modifier le produit</Typography>
              <IconButton 
                onClick={handleCloseEditProductDialog} 
                sx={{ color: 'white' }}
                aria-label="Fermer"
              >
                <CloseIcon />
              </IconButton>
            </Box>
            
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', my: 3 }}>
              <Avatar
                src={selectedProduct && selectedProduct.image && typeof selectedProduct.image === 'string' ? selectedProduct.image : (selectedProduct && selectedProduct.image ? URL.createObjectURL(selectedProduct.image) : undefined)}
                sx={{ 
                  width: 120, 
                  height: 120, 
                  mb: 1, 
                  bgcolor: 'rgba(255,255,255,0.2)',
                  boxShadow: '0 4px 20px rgba(0,0,0,0.2)',
                  border: '4px solid rgba(255,255,255,0.3)'
                }}
              >
                {!selectedProduct?.image && <AddAPhotoIcon sx={{ fontSize: 60 }} />}
              </Avatar>
              <IconButton
                component="label"
                sx={{ 
                  position: 'relative', 
                  top: -30, 
                  left: 40, 
                  bgcolor: 'secondary.main',
                  boxShadow: 2,
                  '&:hover': { bgcolor: 'secondary.dark' } 
                }}
                size="small"
              >
                <AddAPhotoIcon sx={{ color: 'white' }} />
                <input type="file" accept="image/*" hidden onChange={e => {
                  setSelectedProduct({ ...selectedProduct, image: e.target.files[0] });
                }} />
              </IconButton>
              <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.7)', textAlign: 'center', mt: -2 }}>
                Photo du produit
              </Typography>
            </Box>

            {selectedProduct && (
              <Box sx={{ flexGrow: 1 }}>
                <Typography variant="body1" sx={{ mb: 2, fontWeight: 'medium' }}>
                  Informations du produit:
            </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <ShoppingBasketIcon sx={{ mr: 1, fontSize: 20 }} />
                  <Typography variant="body2" noWrap>
                    {selectedProduct.nom || 'Nom du produit'}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <CategoryIcon sx={{ mr: 1, fontSize: 20 }} />
                  <Typography variant="body2" noWrap>
                    {selectedProduct.categorie || 'Catégorie'}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <AttachMoneyIcon sx={{ mr: 1, fontSize: 20 }} />
                  <Typography variant="body2" noWrap>
                    {selectedProduct.prix || 'Prix'}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <DescriptionIcon sx={{ mr: 1, fontSize: 20 }} />
                  <Typography variant="body2" noWrap>
                    {selectedProduct.description || 'Description'}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <CheckCircleIcon sx={{ mr: 1, fontSize: 20, color: selectedProduct.disponible ? 'lightgreen' : 'grey.500' }} />
                  <Typography variant="body2" noWrap>
                    {selectedProduct.disponible ? 'Disponible' : 'Indisponible'}
                  </Typography>
                </Box>
              </Box>
            )}

            <Box sx={{ mt: 'auto', pt: 3 }}>
              <Typography variant="body2" sx={{ color: 'rgba(255,255,255,0.7)', mb: 1 }}>
                * Tous les champs marqués d'un astérisque sont obligatoires
              </Typography>
              <Button 
                variant="contained" 
                fullWidth 
                onClick={handleEditProduct}
                startIcon={<SaveIcon />}
                sx={{ 
                  bgcolor: 'white', 
                  color: 'primary.main',
                  fontWeight: 'bold',
                  '&:hover': { bgcolor: 'rgba(255,255,255,0.9)' }
                }}
              >
                Enregistrer
              </Button>
              <Button 
                variant="outlined" 
                fullWidth 
                onClick={handleCloseEditProductDialog}
                startIcon={<CancelIcon />}
                sx={{ 
                  mt: 1, 
                  borderColor: 'rgba(255,255,255,0.5)', 
                  color: 'white',
                  '&:hover': { borderColor: 'white', bgcolor: 'rgba(255,255,255,0.1)' }
                }}
              >
                Annuler
              </Button>
            </Box>
          </Box>

          {/* القسم الرئيسي للنموذج */}
          <Box sx={{ 
            flexGrow: 1,
            p: 0,
            overflowY: 'auto',
            display: 'flex',
            flexDirection: 'column'
          }}>
            <Box sx={{ 
              bgcolor: 'rgba(25, 118, 210, 0.05)',
              borderBottom: '1px solid rgba(0,0,0,0.08)',
              p: 2
            }}>
              <Typography variant="h6" fontWeight="bold" color="primary">
                Modification du produit
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Modifiez les informations du produit avec précision
              </Typography>
            </Box>

            <Box sx={{ p: 3, flexGrow: 1 }}>
            {selectedProduct && (
              <Grid container spacing={3}>
                <Grid item xs={12} sm={6}>
                    <TextField 
                      label="Nom du produit *" 
                      value={selectedProduct.nom} 
                      onChange={e => setSelectedProduct({ ...selectedProduct, nom: e.target.value })} 
                      fullWidth 
                      required
                      InputProps={{
                        startAdornment: <ShoppingBasketIcon color="action" sx={{ mr: 1 }} />
                      }}
                    />
                </Grid>
                <Grid item xs={12} sm={6}>
                    <TextField 
                      label="Catégorie" 
                      value={selectedProduct.categorie} 
                      onChange={e => setSelectedProduct({ ...selectedProduct, categorie: e.target.value })} 
                      fullWidth 
                      InputProps={{
                        startAdornment: <CategoryIcon color="action" sx={{ mr: 1 }} />
                      }}
                    />
                </Grid>
                <Grid item xs={12} sm={6}>
                    <TextField 
                      label="Prix *" 
                      type="number" 
                      value={selectedProduct.prix} 
                      onChange={e => setSelectedProduct({ ...selectedProduct, prix: e.target.value })} 
                      fullWidth 
                      required
                      InputProps={{
                        startAdornment: <AttachMoneyIcon color="action" sx={{ mr: 1 }} />
                      }}
                    />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <FormControlLabel
                      control={
                        <Switch 
                          checked={selectedProduct.disponible} 
                          onChange={e => setSelectedProduct({ ...selectedProduct, disponible: e.target.checked })}
                          color="success"
                        />
                      }
                      label={
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <CheckCircleIcon sx={{ mr: 1, color: selectedProduct.disponible ? 'success.main' : 'action.disabled' }} />
                          <Typography>Disponible</Typography>
                        </Box>
                      }
                    sx={{ mt: 1 }}
                  />
                </Grid>
                <Grid item xs={12}>
                    <TextField 
                      label="Description" 
                      multiline 
                      rows={4} 
                      value={selectedProduct.description} 
                      onChange={e => setSelectedProduct({ ...selectedProduct, description: e.target.value })} 
                      fullWidth
                      InputProps={{
                        startAdornment: <DescriptionIcon color="action" sx={{ mr: 1, alignSelf: 'flex-start', mt: 1 }} />
                      }}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <Box sx={{ 
                      p: 2, 
                      border: '1px dashed', 
                      borderColor: 'primary.main',
                      borderRadius: 2,
                      bgcolor: 'rgba(25, 118, 210, 0.04)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center'
                    }}>
                      <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
                        Ce produit est associé au fournisseur: <strong>{viewProvider?.nom}</strong>
                      </Typography>
                    </Box>
                </Grid>
              </Grid>
            )}
            </Box>

            <Box sx={{ 
              p: 2, 
              borderTop: '1px solid rgba(0,0,0,0.08)',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              bgcolor: 'rgba(0,0,0,0.02)'
            }}>
              <Button 
                onClick={handleCloseEditProductDialog}
                startIcon={<CancelIcon />}
              >
                Annuler
              </Button>
              <Button 
                variant="contained" 
                color="success"
                onClick={handleEditProduct}
                startIcon={<CheckCircleIcon />}
              >
                Enregistrer les modifications
              </Button>
            </Box>
          </Box>
        </Box>
      </Dialog>

      {/* Dialog تأكيد الحذف */}
      <Dialog open={deleteDialogOpen} onClose={cancelDeleteProduct} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ color: 'error.main', fontWeight: 700 }}>Confirmation de suppression</DialogTitle>
        <DialogContent>
          <Typography variant="body1" sx={{ fontWeight: 600, mb: 2 }}>
            Êtes-vous sûr de vouloir supprimer ce produit ? Cette action est irréversible.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={cancelDeleteProduct} color="inherit" variant="outlined">Annuler</Button>
          <Button onClick={confirmDeleteProduct} color="error" variant="contained">Supprimer</Button>
        </DialogActions>
      </Dialog>

      {/* Dialog معاينة الطباعة والتصدير */}
      <Dialog open={openPrintDialog} onClose={() => setOpenPrintDialog(false)} maxWidth="lg" fullWidth>
        <DialogTitle sx={{ p: 0 }}>
          <Box display="flex" flexDirection="column" alignItems="center" justifyContent="center" py={3}>
            <img src="/Tawssil_logo.png" alt="Tawssil Logo" style={{ width: 120, marginBottom: 8 }} />
            <Typography variant="h5" fontWeight={800} color="#2F9C95" gutterBottom>
              Liste professionnelle des fournisseurs
            </Typography>
            <Typography variant="subtitle2" color="textSecondary">
              {`Date d'impression : ${new Date().toLocaleString('fr-FR')}`}
            </Typography>
            <Typography variant="subtitle2" color="textSecondary">
              {`Nombre total de fournisseurs : ${printProviders.length}`}
            </Typography>
          </Box>
        </DialogTitle>
        <DialogContent dividers>
          <Box id="print-preview-table-provider" sx={{ p: 2, background: '#f8fafc', borderRadius: 3 }}>
            <TableContainer component={Paper} sx={{ boxShadow: 2, borderRadius: 3 }}>
              <Table size="small">
                <TableHead>
                  <TableRow sx={{ background: '#e0f2f1' }}>
                    <TableCell sx={{ fontWeight: 700 }}>ID</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Nom</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Type</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>E-mail</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Téléphone</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Adresse</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Commandes</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Revenu</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Produits</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Statut</TableCell>
                    <TableCell sx={{ fontWeight: 700 }}>Date d'inscription</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {printProviders.map((provider) => (
                    <TableRow key={provider.id}>
                      <TableCell>{provider.id}</TableCell>
                      <TableCell>{provider.nom}</TableCell>
                      <TableCell>{provider.type}</TableCell>
                      <TableCell>{provider.email}</TableCell>
                      <TableCell>{provider.telephone}</TableCell>
                      <TableCell>{provider.adresse}</TableCell>
                      <TableCell>{Array.isArray(provider.commandes) ? provider.commandes.length : (typeof provider.commandes === 'number' ? provider.commandes : 0)}</TableCell>
                      <TableCell>{(provider.revenu || 0).toLocaleString()}</TableCell>
                      <TableCell>{provider.produits}</TableCell>
                      <TableCell>{provider.statut}</TableCell>
                      <TableCell>{provider.date_inscription}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenPrintDialog(false)} color="primary">FERMER</Button>
          <Button
            onClick={() => {
              const printContent = document.getElementById('print-preview-table-provider');
              const detailsContent = document.getElementById('print-details-providers');
              const printWindow = window.open('', '', 'width=900,height=700');
              printWindow.document.write('<html><head><title>Liste des fournisseurs</title>');
              printWindow.document.write(`
                <style>
                  @page { size: A4; margin: 1cm; }
                  body {
                    font-family: Arial, sans-serif;
                    line-height: 1.5;
                    color: #333;
                  }
                  .header {
                    text-align: center;
                    margin-bottom: 20px;
                    position: relative;
                  }
                  .logo {
                    width: 100px;
                    margin: 0 auto 10px;
                    display: block;
                  }
                  .title {
                    color: #2F9C95;
                    font-size: 24px;
                    font-weight: bold;
                    margin: 10px 0;
                  }
                  .subtitle {
                    color: #666;
                    font-size: 14px;
                    margin: 5px 0;
                  }
                  table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-bottom: 20px;
                    font-size: 12px;
                  }
                  th, td {
                    border: 1px solid #ccc;
                    padding: 8px;
                    text-align: left;
                  }
                  th {
                    background: #e0f2f1;
                    font-weight: bold;
                  }
                  tr:nth-child(even) {
                    background-color: #f9f9f9;
                  }
                  .details-section {
                    margin-top: 30px;
                    page-break-before: always;
                  }
                  .details-title {
                    color: #2F9C95;
                    font-size: 18px;
                    font-weight: bold;
                    margin: 20px 0 10px;
                    border-bottom: 2px solid #2F9C95;
                    padding-bottom: 5px;
                  }
                  .provider-card {
                    background: #f5f5f5;
                    border-radius: 5px;
                    padding: 15px;
                    margin-bottom: 20px;
                    border-left: 5px solid #2F9C95;
                  }
                  .provider-name {
                    font-size: 16px;
                    font-weight: bold;
                    margin-bottom: 10px;
                  }
                  .section-title {
                    font-weight: bold;
                    margin: 15px 0 5px;
                    font-size: 14px;
                    color: #555;
                  }
                  .no-data {
                    color: #888;
                    font-style: italic;
                    margin: 5px 0;
                  }
                  .footer {
                    text-align: center;
                    margin-top: 30px;
                    font-size: 12px;
                    color: #666;
                    border-top: 1px solid #ccc;
                    padding-top: 10px;
                  }
                  @media print {
                    .no-print {
                      display: none;
                    }
                    a {
                      text-decoration: none;
                      color: #333;
                    }
                    .MuiChip-root {
                      border: 1px solid #ccc !important;
                      background-color: transparent !important;
                    }
                    .MuiChip-colorSuccess {
                      color: #2e7d32 !important;
                      border-color: #2e7d32 !important;
                    }
                    .MuiChip-colorError {
                      color: #d32f2f !important;
                      border-color: #d32f2f !important;
                    }
                    .MuiChip-colorPrimary {
                      color: #1976d2 !important;
                      border-color: #1976d2 !important;
                    }
                  }
                </style>
              `);
              printWindow.document.write('</head><body>');
              
              // Header
              printWindow.document.write(`
                <div class="header">
                  <img src="/Tawssil_logo.png" alt="Tawssil Logo" class="logo" />
                  <h1 class="title">Liste professionnelle des fournisseurs</h1>
                  <p class="subtitle">Date d'impression : ${new Date().toLocaleString('fr-FR')}</p>
                  <p class="subtitle">Nombre total de fournisseurs : ${printProviders.length}</p>
                </div>
              `);
              
              // Main Table
              printWindow.document.write(printContent.innerHTML);
              
              // Details Section
              printWindow.document.write('<div class="details-section">');
              printWindow.document.write('<h2 class="details-title">Détails supplémentaires</h2>');
              
              // Utilisation de detailsContent au lieu de créer manuellement le contenu
              printWindow.document.write(detailsContent.innerHTML);
              
              // Footer
              printWindow.document.write(`
                <div class="footer">
                  Imprimé par : ${localStorage.getItem('adminUser') ? JSON.parse(localStorage.getItem('adminUser')).username : 'Admin'} | 
                  Tawssil © ${new Date().getFullYear()}
                </div>
              `);
              
              printWindow.document.write('</body></html>');
              printWindow.document.close();
              printWindow.focus();
              setTimeout(() => {
              printWindow.print();
              }, 500);
            }}
            color="success"
            variant="contained"
            startIcon={<PrintIcon />}
          >
            IMPRIMER
          </Button>
          <Button
            variant="outlined"
            color="secondary"
            onClick={e => setExportAnchorEl(e.currentTarget)}
            sx={{ ml: 1 }}
          >
            Exporter
          </Button>
          <Menu anchorEl={exportAnchorEl} open={Boolean(exportAnchorEl)} onClose={() => setExportAnchorEl(null)}>
            <MenuItem onClick={() => { setExportType('pdf'); setExportAnchorEl(null); setOpenExportDialog(true); }}>PDF</MenuItem>
            <MenuItem onClick={() => { setExportType('excel'); setExportAnchorEl(null); setOpenExportDialog(true); }}>Excel</MenuItem>
            <MenuItem onClick={() => { setExportType('word'); setExportAnchorEl(null); setOpenExportDialog(true); }}>Word</MenuItem>
          </Menu>
          {/* Dialog اختيار نوع التصدير */}
          <Dialog open={openExportDialog} onClose={() => setOpenExportDialog(false)} maxWidth="xs" fullWidth>
            <DialogTitle>Exporter la liste</DialogTitle>
            <DialogContent>
              <Typography>Vous avez choisi d'exporter la liste des fournisseurs au format <b>{exportType.toUpperCase()}</b>.</Typography>
              <Typography mt={2}>Voulez-vous continuer ?</Typography>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setOpenExportDialog(false)} color="secondary">Annuler</Button>
              <Button onClick={() => {
                setOpenExportDialog(false);
                if (exportType === 'excel') exportToExcel();
                else if (exportType === 'word') exportToWord();
                else if (exportType === 'pdf') {
                  const printContent = document.getElementById('print-preview-table-provider');
                  const printWindow = window.open('', '', 'width=900,height=700');
                  printWindow.document.write('<html><head><title>Liste des fournisseurs</title>');
                  printWindow.document.write('<style>body{font-family:sans-serif;}table{width:100%;border-collapse:collapse;}th,td{border:1px solid #ccc;padding:6px;text-align:left;}th{background:#e0f2f1;}h1{text-align:center;color:#2F9C95;}img{display:block;margin:0 auto 10px auto;width:100px;}@media print{.MuiDialogActions-root{display:none;}}</style>');
                  printWindow.document.write('</head><body >');
                  printWindow.document.write(`<img src='/Tawssil_logo.png' alt='Tawssil Logo' /><h1>Liste professionnelle des fournisseurs</h1>`);
                  printWindow.document.write(printContent.innerHTML);
                  printWindow.document.write('<div style="text-align:center;margin-top:20px;font-size:12px;color:#666;">Imprimé par : ' + (localStorage.getItem('adminUser') ? JSON.parse(localStorage.getItem('adminUser')).username : 'Admin') + '</div>');
                  printWindow.document.write('</body></html>');
                  printWindow.document.close();
                  printWindow.focus();
                  printWindow.print();
                }
              }} color="primary" variant="contained">Exporter</Button>
            </DialogActions>
          </Dialog>
        </DialogActions>
        {/* تفاصيل إضافية لكل مزود */}
        <DialogContent dividers>
          <Box sx={{ mt: 4 }} id="print-details-providers">
            <Typography variant="h6" fontWeight={700} color="#2F9C95" gutterBottom>
              Détails supplémentaires
            </Typography>
            {printProviders.map((provider, idx) => (
              <Paper key={provider.id} sx={{ p: 2, mb: 2, background: idx % 2 === 0 ? '#f1f8e9' : '#e3f2fd', borderRadius: 2, boxShadow: 2 }}>
                <Typography variant="subtitle1" fontWeight={700} color="#333">
                  {provider.nom} ({provider.type})
                </Typography>
                {/* تفاصيل الطلبات */}
                <Typography variant="body2" color="textSecondary" sx={{ mt: 1, mb: 1, fontWeight: 'bold' }}>
                  Commandes :
                </Typography>
                {Array.isArray(provider.commandes) && provider.commandes.length > 0 ? (
                  <TableContainer component={Paper} sx={{ mb: 2, boxShadow: 1 }}>
                    <Table size="small">
                      <TableHead>
                        <TableRow sx={{ background: '#e8f5e9' }}>
                          <TableCell sx={{ fontWeight: 'bold' }}>ID</TableCell>
                          <TableCell sx={{ fontWeight: 'bold' }}>Date</TableCell>
                          <TableCell sx={{ fontWeight: 'bold' }}>Montant</TableCell>
                          <TableCell sx={{ fontWeight: 'bold' }}>Statut</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {provider.commandes.map((cmd) => (
                          <TableRow key={cmd.id_commande}>
                            <TableCell>{cmd.id_commande}</TableCell>
                            <TableCell>{cmd.date_commande || '-'}</TableCell>
                            <TableCell>{cmd.montant_total || '-'}</TableCell>
                            <TableCell>
                              <Chip 
                                label={cmd.statut || '-'} 
                                size="small"
                                color={
                                  cmd.statut === 'Livrée' ? 'success' :
                                  cmd.statut === 'En livraison' ? 'primary' :
                                  cmd.statut === 'Annulée' ? 'error' : 'default'
                                }
                              />
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                ) : (
                  <Typography variant="body2" color="#888" sx={{ fontStyle: 'italic', ml: 2 }}>
                    Aucune commande trouvée.
                  </Typography>
                )}
                {/* تفاصيل المنتجات */}
                <Typography variant="body2" color="textSecondary" sx={{ mt: 2, mb: 1, fontWeight: 'bold' }}>
                  Produits :
                </Typography>
                {Array.isArray(provider.products) && provider.products.length > 0 ? (
                  <TableContainer component={Paper} sx={{ mb: 2, boxShadow: 1 }}>
                    <Table size="small">
                      <TableHead>
                        <TableRow sx={{ background: '#e3f2fd' }}>
                          <TableCell sx={{ fontWeight: 'bold' }}>Nom</TableCell>
                          <TableCell sx={{ fontWeight: 'bold' }}>Description</TableCell>
                          <TableCell sx={{ fontWeight: 'bold' }}>Prix</TableCell>
                          <TableCell sx={{ fontWeight: 'bold' }}>Catégorie</TableCell>
                          <TableCell sx={{ fontWeight: 'bold' }}>Disponible</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {provider.products.map((prod) => (
                          <TableRow key={prod.id}>
                            <TableCell>{prod.nom}</TableCell>
                            <TableCell>{prod.description || '-'}</TableCell>
                            <TableCell>{prod.prix || '-'} UM</TableCell>
                            <TableCell>{prod.categorie || '-'}</TableCell>
                            <TableCell>
                              <Chip 
                                label={prod.disponible ? 'Oui' : 'Non'} 
                                size="small"
                                color={prod.disponible ? 'success' : 'error'}
                              />
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                ) : (
                  <Typography variant="body2" color="#888" sx={{ fontStyle: 'italic', ml: 2 }}>
                    Aucun produit trouvé.
                  </Typography>
                )}
              </Paper>
            ))}
          </Box>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default ProviderManagement; 