import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../shared/custom_text_form_filed.dart';
import '../../widgets/app_widgets.dart';

/// Add a product (product == null) or edit an existing one.
class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _description = TextEditingController(text: widget.product?.description);
  late final _price = TextEditingController(text: widget.product?.price.toString());
  late final _imageUrl = TextEditingController(text: widget.product?.imageUrl);
  late final _category = TextEditingController(text: widget.product?.category);
  late final _stock = TextEditingController(text: widget.product?.stock.toString());
  late bool _isAvailable = widget.product?.isAvailable ?? true;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _imageUrl, _category, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'this field is required' : null;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final product = Product(
      id: widget.product?.id ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      price: double.parse(_price.text.trim()),
      imageUrl: _imageUrl.text.trim(),
      category: _category.text.trim(),
      stock: int.parse(_stock.text.trim()),
      isAvailable: _isAvailable,
    );

    try {
      final service = ProductService();
      if (_isEdit) {
        await service.updateProduct(widget.product!.id, product);
      } else {
        await service.addProduct(product);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message ?? 'Could not save product', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'New product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                  controller: _name,
                  label: 'Name',
                  icon: Icons.label_outline,
                  validator: _required),
              const Gap(16),
              AppTextField(
                  controller: _description,
                  label: 'Description',
                  icon: Icons.notes,
                  maxLines: 3,
                  validator: _required),
              const Gap(16),
              AppTextField(
                controller: _price,
                label: 'Price',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  return (n == null || n <= 0) ? 'enter a valid price' : null;
                },
              ),
              const Gap(16),
              AppTextField(
                  controller: _imageUrl,
                  label: 'Image URL',
                  icon: Icons.image_outlined,
                  keyboardType: TextInputType.url,
                  validator: _required),
              const Gap(16),
              AppTextField(
                  controller: _category,
                  label: 'Category',
                  icon: Icons.category_outlined,
                  validator: _required),
              const Gap(16),
              AppTextField(
                controller: _stock,
                label: 'Stock quantity',
                icon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  return (n == null || n < 0) ? 'enter a valid quantity' : null;
                },
              ),
              SwitchListTile(
                title: const Text('Available for sale'),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),
              const Gap(16),
              PrimaryButton(text: 'Save', onPressed: _save, isLoading: _saving),
            ],
          ),
        ),
      ),
    );
  }
}
