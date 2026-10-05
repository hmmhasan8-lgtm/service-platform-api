'use client';

import React, { useState } from 'react';
import {
  ShieldCheck,
  Layers,
  Table,
  Plus,
  Sliders,
  FileText,
  Check,
  Edit3,
  Globe,
  LogOut,
  Power,
  Trash2,
  Sparkles,
  Tag,
  Percent,
} from 'lucide-react';
import { FieldBuilder, GenericColumnDefinition } from '../../components/FieldBuilder';

export interface CouponItem {
  id: string;
  code: string;
  discount_percent: number;
  max_uses: number;
  used_count: number;
  is_active: boolean;
  valid_until: string;
}

export interface EntityItem {
  id: string;
  module_id: string;
  module_key: string;
  entity_key: string;
  name: { en: string; bn: string };
  unlock_fee_usd: number;
  validity_days: number;
  is_active: boolean;
  field_definitions?: GenericColumnDefinition[];
}

export interface ModuleItem {
  id: string;
  module_key: string;
  name: { en: string; bn: string };
  icon: string;
  is_active: boolean;
  allowed_countries: string[];
}

// Initial 15 Columns preset for Entities
export const DEFAULT_ENTITY_COLUMNS: Record<string, GenericColumnDefinition[]> = {
  vehicles: [
    { col_key: 'custom_col_1', label_en: 'Fuel Type', label_bn: 'জ্বালানির ধরন', data_type: 'select', is_private: false, is_active: true, options: ['CNG', 'Petrol', 'Octane', 'Electric'] },
    { col_key: 'custom_col_2', label_en: 'Security Deposit', label_bn: 'জামানতের পরিমাণ', data_type: 'currency', is_private: false, is_active: true },
    { col_key: 'custom_col_3', label_en: 'Hourly Rate', label_bn: 'ঘণ্টাপ্রতি ভাড়া', data_type: 'currency', is_private: false, is_active: true },
    { col_key: 'custom_col_4', label_en: 'Vehicle Model Year', label_bn: 'মডেল সাল', data_type: 'number', is_private: false, is_active: true },
    { col_key: 'custom_col_5', label_en: 'Seating Capacity', label_bn: 'আসন সংখ্যা', data_type: 'number', is_private: false, is_active: true },
    { col_key: 'custom_col_6', label_en: 'Owner Direct Mobile', label_bn: 'মালিকের সরাসরি মোবাইল', data_type: 'phone', is_private: true, is_active: true },
    { col_key: 'custom_col_7', label_en: 'Exact Garage Address', label_bn: 'গ্যারেজের নির্ভুল ঠিকানা', data_type: 'geo_point', is_private: true, is_active: true },
    { col_key: 'custom_col_8', label_en: 'AC Condition', label_bn: 'এসি কন্ডিশন', data_type: 'select', is_private: false, is_active: false, options: ['Chilled AC', 'Standard', 'Non-AC'] },
    { col_key: 'custom_col_9', label_en: 'Driver Included?', label_bn: 'ড্রাইভার সহ?', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_10', label_en: 'Custom Field 10', label_bn: 'কাস্টম ফিল্ড ১০', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_11', label_en: 'Custom Field 11', label_bn: 'কাস্টম ফিল্ড ১১', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_12', label_en: 'Custom Field 12', label_bn: 'কাস্টম ফিল্ড ১২', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_13', label_en: 'Custom Field 13', label_bn: 'কাস্টম ফিল্ড ১৩', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_14', label_en: 'Custom Field 14', label_bn: 'কাস্টম ফিল্ড ১৪', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_15', label_en: 'Custom Field 15', label_bn: 'কাস্টম ফিল্ড ১৫', data_type: 'text', is_private: false, is_active: false },
  ],
  services: [
    { col_key: 'custom_col_1', label_en: 'Service Category', label_bn: 'সেবার ক্যাটাগরি', data_type: 'select', is_private: false, is_active: true, options: ['AC Repair', 'Plumbing', 'Electrical', 'Cleaning'] },
    { col_key: 'custom_col_2', label_en: 'Minimum Visiting Charge', label_bn: 'ভিজিটিং চার্জ', data_type: 'currency', is_private: false, is_active: true },
    { col_key: 'custom_col_3', label_en: 'Warranty Days', label_bn: 'সার্ভিস ওয়ারেন্টি (দিন)', data_type: 'number', is_private: false, is_active: true },
    { col_key: 'custom_col_4', label_en: 'Technician Direct Mobile', label_bn: 'টেকনিশিয়ান সরাসরি মোবাইল', data_type: 'phone', is_private: true, is_active: true },
    { col_key: 'custom_col_5', label_en: 'Workshop Holding Address', label_bn: 'ওয়ার্কশপের হোল্ডিং ঠিকানা', data_type: 'geo_point', is_private: true, is_active: true },
    { col_key: 'custom_col_6', label_en: 'Custom Field 6', label_bn: 'কাস্টম ফিল্ড ৬', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_7', label_en: 'Custom Field 7', label_bn: 'কাস্টম ফিল্ড ৭', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_8', label_en: 'Custom Field 8', label_bn: 'কাস্টম ফিল্ড ৮', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_9', label_en: 'Custom Field 9', label_bn: 'কাস্টম ফিল্ড ৯', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_10', label_en: 'Custom Field 10', label_bn: 'কাস্টম ফিল্ড ১০', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_11', label_en: 'Custom Field 11', label_bn: 'কাস্টম ফিল্ড ১১', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_12', label_en: 'Custom Field 12', label_bn: 'কাস্টম ফিল্ড ১২', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_13', label_en: 'Custom Field 13', label_bn: 'কাস্টম ফিল্ড ১৩', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_14', label_en: 'Custom Field 14', label_bn: 'কাস্টম ফিল্ড ১৪', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_15', label_en: 'Custom Field 15', label_bn: 'কাস্টম ফিল্ড ১৫', data_type: 'text', is_private: false, is_active: false },
  ],
  drivers: [
    { col_key: 'custom_col_1', label_en: 'License Type', label_bn: 'লাইসেন্স টাইপ', data_type: 'select', is_private: false, is_active: true, options: ['Light', 'Medium', 'Heavy Professional'] },
    { col_key: 'custom_col_2', label_en: 'Experience (Years)', label_bn: 'অভিজ্ঞতা (বছর)', data_type: 'number', is_private: false, is_active: true },
    { col_key: 'custom_col_3', label_en: 'Monthly Salary Expectation', label_bn: 'মাসিক বেতন প্রত্যাশা', data_type: 'currency', is_private: false, is_active: true },
    { col_key: 'custom_col_4', label_en: 'Driver Direct Mobile', label_bn: 'ড্রাইভার সরাসরি মোবাইল', data_type: 'phone', is_private: true, is_active: true },
    { col_key: 'custom_col_5', label_en: 'Driving License No', label_bn: 'লাইসেন্স নম্বর', data_type: 'text', is_private: true, is_active: true },
    { col_key: 'custom_col_6', label_en: 'Custom Field 6', label_bn: 'কাস্টম ফিল্ড ৬', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_7', label_en: 'Custom Field 7', label_bn: 'কাস্টম ফিল্ড ৭', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_8', label_en: 'Custom Field 8', label_bn: 'কাস্টম ফিল্ড ৮', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_9', label_en: 'Custom Field 9', label_bn: 'কাস্টম ফিল্ড ৯', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_10', label_en: 'Custom Field 10', label_bn: 'কাস্টম ফিল্ড ১০', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_11', label_en: 'Custom Field 11', label_bn: 'কাস্টম ফিল্ড ১১', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_12', label_en: 'Custom Field 12', label_bn: 'কাস্টম ফিল্ড ১২', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_13', label_en: 'Custom Field 13', label_bn: 'কাস্টম ফিল্ড ১৩', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_14', label_en: 'Custom Field 14', label_bn: 'কাস্টম ফিল্ড ১৪', data_type: 'text', is_private: false, is_active: false },
    { col_key: 'custom_col_15', label_en: 'Custom Field 15', label_bn: 'কাস্টম ফিল্ড ১৫', data_type: 'text', is_private: false, is_active: false },
  ],
};

interface FounderControlPageProps {
  entityColumnsState?: Record<string, GenericColumnDefinition[]>;
  entitiesList?: EntityItem[];
  modulesList?: ModuleItem[];
  onSaveColumnsGlobal?: (entityKey: string, columns: GenericColumnDefinition[]) => void;
  onUpdateEntitiesGlobal?: (entities: EntityItem[]) => void;
  onUpdateModulesGlobal?: (modules: ModuleItem[]) => void;
}

export default function FounderControlPage({
  entityColumnsState,
  entitiesList,
  modulesList,
  onSaveColumnsGlobal,
  onUpdateEntitiesGlobal,
  onUpdateModulesGlobal,
}: FounderControlPageProps) {
  const [isAuthenticated, setIsAuthenticated] = useState(true);
  const [activeTab, setActiveTab] = useState<'entities' | 'modules' | 'rename_columns' | 'coupons' | 'audit'>('entities');
  const [selectedEntityKey, setSelectedEntityKey] = useState<string>('vehicles');

  // MODULE 3: Marketing Coupons State
  const [coupons, setCoupons] = useState<CouponItem[]>([
    {
      id: 'c1',
      code: 'EID50',
      discount_percent: 50,
      max_uses: 500,
      used_count: 84,
      is_active: true,
      valid_until: '2026-11-30',
    },
    {
      id: 'c2',
      code: 'SERVICE20',
      discount_percent: 20,
      max_uses: 1000,
      used_count: 312,
      is_active: true,
      valid_until: '2026-12-31',
    },
    {
      id: 'c3',
      code: 'PROMO100',
      discount_percent: 100,
      max_uses: 50,
      used_count: 18,
      is_active: false,
      valid_until: '2026-10-31',
    },
  ]);
  const [showCreateCouponModal, setShowCreateCouponModal] = useState(false);
  const [couponFormCode, setCouponFormCode] = useState('');
  const [couponFormDiscount, setCouponFormDiscount] = useState<number>(50);
  const [couponFormMaxUses, setCouponFormMaxUses] = useState<number>(500);
  const [couponFormValidDays, setCouponFormValidDays] = useState<number>(30);

  // Shared / Local 15 Columns state
  const [columnsState, setColumnsState] = useState<Record<string, GenericColumnDefinition[]>>(
    entityColumnsState || DEFAULT_ENTITY_COLUMNS
  );

  // Modules List
  const [modules, setModules] = useState<ModuleItem[]>(
    modulesList || [
      {
        id: '11111111-1111-1111-1111-111111111111',
        module_key: 'vehicle_rental',
        name: { en: 'Vehicle Rental & Logistics', bn: 'যানবাহন ও লজিস্টিকস ভাড়া' },
        icon: 'car',
        is_active: true,
        allowed_countries: ['BD', 'IN', 'US'],
      },
      {
        id: '22222222-2222-2222-2222-222222222222',
        module_key: 'service_marketplace',
        name: { en: 'Professional Services', bn: 'পেশাদার সেবা মার্কেটপ্লেস' },
        icon: 'wrench',
        is_active: true,
        allowed_countries: ['*'],
      },
    ]
  );

  // Entities (Tables) List
  const [entities, setEntities] = useState<EntityItem[]>(
    entitiesList || [
      {
        id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        module_id: '11111111-1111-1111-1111-111111111111',
        module_key: 'vehicle_rental',
        entity_key: 'vehicles',
        name: { en: 'Rental Vehicles', bn: 'ভাড়ার যানবাহন' },
        unlock_fee_usd: 1.0,
        validity_days: 7,
        is_active: true,
      },
      {
        id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        module_id: '22222222-2222-2222-2222-222222222222',
        module_key: 'service_marketplace',
        entity_key: 'services',
        name: { en: 'Home & Commercial Services', bn: 'বাসাবাড়ি ও বাণিজ্যিক সেবা' },
        unlock_fee_usd: 0.5,
        validity_days: 7,
        is_active: true,
      },
      {
        id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        module_id: '11111111-1111-1111-1111-111111111111',
        module_key: 'vehicle_rental',
        entity_key: 'drivers',
        name: { en: 'Verified Drivers', bn: 'ভেরিফায়েড ড্রাইভার' },
        unlock_fee_usd: 0.75,
        validity_days: 7,
        is_active: true,
      },
    ]
  );

  // Modals State
  const [showCreateModuleModal, setShowCreateModuleModal] = useState(false);
  const [editingModule, setEditingModule] = useState<ModuleItem | null>(null);

  const [showCreateEntityModal, setShowCreateEntityModal] = useState(false);
  const [editingEntity, setEditingEntity] = useState<EntityItem | null>(null);

  // Form States for Module
  const [moduleFormKey, setModuleFormKey] = useState('');
  const [moduleFormNameEn, setModuleFormNameEn] = useState('');
  const [moduleFormNameBn, setModuleFormNameBn] = useState('');
  const [moduleFormCountries, setModuleFormCountries] = useState<string[]>(['*']);

  // Form States for Entity
  const [entityFormModuleId, setEntityFormModuleId] = useState(modules[0]?.id || '');
  const [entityFormKey, setEntityFormKey] = useState('');
  const [entityFormNameEn, setEntityFormNameEn] = useState('');
  const [entityFormNameBn, setEntityFormNameBn] = useState('');
  const [entityFormUnlockFee, setEntityFormUnlockFee] = useState<number>(0.5);
  const [entityFormValidity, setEntityFormValidity] = useState<number>(7);

  // Audit Logs
  const [auditLogs, setAuditLogs] = useState([
    {
      id: 'log_1',
      actor: 'founder_admin (hmmhasan8@gmail.com)',
      action: 'entities.created',
      entity: 'vehicles',
      timestamp: 'Just now',
      details: 'Registered table vehicles with 15 generic columns',
    },
  ]);

  // Sync helpers
  const syncModules = (updated: ModuleItem[]) => {
    setModules(updated);
    if (onUpdateModulesGlobal) onUpdateModulesGlobal(updated);
  };

  const syncEntities = (updated: EntityItem[]) => {
    setEntities(updated);
    if (onUpdateEntitiesGlobal) onUpdateEntitiesGlobal(updated);
  };

  // -------------------------------------------------------------------------
  // MODULE HANDLERS (POST & PUT)
  // -------------------------------------------------------------------------
  const handleCreateModule = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!moduleFormKey.trim()) return;

    const mKey = moduleFormKey.trim().toLowerCase().replace(/\s+/g, '_');
    const newModule: ModuleItem = {
      id: 'mod_' + Math.random().toString(36).substring(2, 10),
      module_key: mKey,
      name: {
        en: moduleFormNameEn.trim() || mKey,
        bn: moduleFormNameBn.trim() || moduleFormNameEn.trim() || mKey,
      },
      icon: 'layers',
      is_active: true,
      allowed_countries: moduleFormCountries,
    };

    // Try background API call
    try {
      fetch('/founder/modules', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          module_key: newModule.module_key,
          name_en: newModule.name.en,
          name_bn: newModule.name.bn,
          allowed_countries: newModule.allowed_countries,
          is_active: true,
        }),
      }).catch(() => {});
    } catch (e) {}

    const updated = [...modules, newModule];
    syncModules(updated);

    setAuditLogs((prev) => [
      {
        id: 'log_' + Date.now(),
        actor: 'founder_admin (hmmhasan8@gmail.com)',
        action: 'modules.created',
        entity: newModule.module_key,
        timestamp: 'Just now',
        details: `Created new module '${newModule.name.en}' (${newModule.module_key})`,
      },
      ...prev,
    ]);

    setShowCreateModuleModal(false);
    setModuleFormKey('');
    setModuleFormNameEn('');
    setModuleFormNameBn('');
  };

  const handleUpdateModule = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingModule) return;

    const updated = modules.map((m) => {
      if (m.id === editingModule.id) {
        return {
          ...m,
          name: {
            en: moduleFormNameEn.trim() || m.name.en,
            bn: moduleFormNameBn.trim() || m.name.bn,
          },
          allowed_countries: moduleFormCountries,
        };
      }
      return m;
    });

    // Try background API call
    try {
      fetch(`/founder/modules/${editingModule.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name_en: moduleFormNameEn.trim() || editingModule.name.en,
          name_bn: moduleFormNameBn.trim() || editingModule.name.bn,
          allowed_countries: moduleFormCountries,
          is_active: editingModule.is_active,
        }),
      }).catch(() => {});
    } catch (e) {}

    syncModules(updated);
    setAuditLogs((prev) => [
      {
        id: 'log_' + Date.now(),
        actor: 'founder_admin (hmmhasan8@gmail.com)',
        action: 'modules.updated',
        entity: editingModule.module_key,
        timestamp: 'Just now',
        details: `Renamed module '${editingModule.module_key}' to '${moduleFormNameEn}' / '${moduleFormNameBn}'`,
      },
      ...prev,
    ]);

    setEditingModule(null);
  };

  const toggleModuleActive = (moduleId: string) => {
    const updated = modules.map((m) => {
      if (m.id === moduleId) {
        const nextState = !m.is_active;
        try {
          fetch(`/founder/modules/${moduleId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ is_active: nextState }),
          }).catch(() => {});
        } catch (e) {}

        setAuditLogs((prev) => [
          {
            id: 'log_' + Date.now(),
            actor: 'founder_admin (hmmhasan8@gmail.com)',
            action: 'modules.toggle_active',
            entity: m.module_key,
            timestamp: 'Just now',
            details: `Module '${m.module_key}' toggled to ${nextState ? 'ACTIVE' : 'INACTIVE'}`,
          },
          ...prev,
        ]);

        return { ...m, is_active: nextState };
      }
      return m;
    });
    syncModules(updated);
  };

  // -------------------------------------------------------------------------
  // ENTITY (TABLE) HANDLERS (POST & PUT)
  // -------------------------------------------------------------------------
  const handleCreateEntity = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!entityFormKey.trim()) return;

    const eKey = entityFormKey.trim().toLowerCase().replace(/\s+/g, '_');
    const parentModule = modules.find((m) => m.id === entityFormModuleId) || modules[0];

    // Generate 15 default generic columns for this new entity
    const new15Columns: GenericColumnDefinition[] = [];
    for (let i = 1; i <= 15; i++) {
      new15Columns.push({
        col_key: `custom_col_${i}`,
        label_en: i === 1 ? 'Category' : i === 2 ? 'Price / Rate' : i === 3 ? 'Direct Mobile' : `Field ${i}`,
        label_bn: i === 1 ? 'ক্যাটাগরি' : i === 2 ? 'মূল্য / রেট' : i === 3 ? 'সরাসরি মোবাইল' : `ফিল্ড ${i}`,
        data_type: i === 2 ? 'currency' : i === 3 ? 'phone' : 'text',
        is_private: i === 3, // Column 3 locked private
        is_active: i <= 3,
        options: [],
        target_countries: ['*'],
      });
    }

    const newEntity: EntityItem = {
      id: 'ent_' + Math.random().toString(36).substring(2, 10),
      module_id: parentModule.id,
      module_key: parentModule.module_key,
      entity_key: eKey,
      name: {
        en: entityFormNameEn.trim() || eKey,
        bn: entityFormNameBn.trim() || entityFormNameEn.trim() || eKey,
      },
      unlock_fee_usd: Number(entityFormUnlockFee) || 0.5,
      validity_days: Number(entityFormValidity) || 7,
      is_active: true,
      field_definitions: new15Columns,
    };

    // Save default 15 columns for this entity
    setColumnsState((prev) => ({
      ...prev,
      [eKey]: new15Columns,
    }));
    if (onSaveColumnsGlobal) {
      onSaveColumnsGlobal(eKey, new15Columns);
    }

    // Try background API call
    try {
      fetch('/founder/entities', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          module_id: newEntity.module_id,
          entity_key: newEntity.entity_key,
          name_en: newEntity.name.en,
          name_bn: newEntity.name.bn,
          unlock_fee: newEntity.unlock_fee_usd,
          validity_days: newEntity.validity_days,
          is_active: true,
          field_definitions: new15Columns,
        }),
      }).catch(() => {});
    } catch (e) {}

    const updated = [...entities, newEntity];
    syncEntities(updated);

    setAuditLogs((prev) => [
      {
        id: 'log_' + Date.now(),
        actor: 'founder_admin (hmmhasan8@gmail.com)',
        action: 'entities.created',
        entity: newEntity.entity_key,
        timestamp: 'Just now',
        details: `Created new table '${newEntity.name.en}' (${newEntity.entity_key}) in module '${parentModule.module_key}' with 15 generic columns`,
      },
      ...prev,
    ]);

    setShowCreateEntityModal(false);
    setEntityFormKey('');
    setEntityFormNameEn('');
    setEntityFormNameBn('');
  };

  const handleUpdateEntity = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingEntity) return;

    const updated = entities.map((ent) => {
      if (ent.id === editingEntity.id) {
        const next = {
          ...ent,
          name: {
            en: entityFormNameEn.trim() || ent.name.en,
            bn: entityFormNameBn.trim() || ent.name.bn,
          },
          unlock_fee_usd: Number(entityFormUnlockFee) || ent.unlock_fee_usd,
          validity_days: Number(entityFormValidity) || ent.validity_days,
        };

        try {
          fetch(`/founder/entities/${editingEntity.id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              name_en: next.name.en,
              name_bn: next.name.bn,
              unlock_fee: next.unlock_fee_usd,
              validity_days: next.validity_days,
              is_active: next.is_active,
            }),
          }).catch(() => {});
        } catch (e) {}

        return next;
      }
      return ent;
    });

    syncEntities(updated);
    setAuditLogs((prev) => [
      {
        id: 'log_' + Date.now(),
        actor: 'founder_admin (hmmhasan8@gmail.com)',
        action: 'entities.renamed',
        entity: editingEntity.entity_key,
        timestamp: 'Just now',
        details: `Renamed table '${editingEntity.entity_key}' to '${entityFormNameEn}' / '${entityFormNameBn}'`,
      },
      ...prev,
    ]);

    setEditingEntity(null);
  };

  const toggleEntityActive = (entityId: string) => {
    const updated = entities.map((ent) => {
      if (ent.id === entityId) {
        const nextState = !ent.is_active;

        try {
          fetch(`/founder/entities/${entityId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ is_active: nextState }),
          }).catch(() => {});
        } catch (e) {}

        setAuditLogs((prev) => [
          {
            id: 'log_' + Date.now(),
            actor: 'founder_admin (hmmhasan8@gmail.com)',
            action: 'entities.toggle_active',
            entity: ent.entity_key,
            timestamp: 'Just now',
            details: `Table '${ent.entity_key}' toggled to ${nextState ? 'ACTIVE' : 'INACTIVE'}`,
          },
          ...prev,
        ]);

        return { ...ent, is_active: nextState };
      }
      return ent;
    });
    syncEntities(updated);
  };

  // MODULE 4 A: Dynamic Commission Change (Inline Editable Unlock Fee)
  const handleInlineFeeChange = (entityId: string, newFeeUSD: number) => {
    const safeVal = isNaN(newFeeUSD) ? 0.5 : Math.max(0.05, Math.round(newFeeUSD * 100) / 100);
    const updated = entities.map((ent) => {
      if (ent.id === entityId) {
        try {
          fetch(`/founder/entities/${entityId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ unlock_fee: safeVal }),
          }).catch(() => {});
        } catch (e) {}

        setAuditLogs((prev) => [
          {
            id: 'log_' + Date.now(),
            actor: 'founder_admin (hmmhasan8@gmail.com)',
            action: 'entities.fee_changed',
            entity: ent.entity_key,
            timestamp: 'Just now',
            details: `Inline commission changed for '${ent.entity_key}' to $${safeVal.toFixed(2)} USD (≈ ৳${Math.round(safeVal * 120)} BDT)`,
          },
          ...prev,
        ]);

        return { ...ent, unlock_fee_usd: safeVal };
      }
      return ent;
    });
    syncEntities(updated);
  };

  // MODULE 3: Coupon Management Handlers
  const handleCreateCoupon = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!couponFormCode.trim()) return;
    const cleanCode = couponFormCode.trim().toUpperCase();

    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + Number(couponFormValidDays || 30));

    const newCoupon: CouponItem = {
      id: 'coup_' + Math.random().toString(36).substring(2, 9),
      code: cleanCode,
      discount_percent: Number(couponFormDiscount) || 50,
      max_uses: Number(couponFormMaxUses) || 500,
      used_count: 0,
      is_active: true,
      valid_until: expiryDate.toISOString().split('T')[0],
    };

    try {
      fetch('/founder/coupons', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          code: cleanCode,
          discount_percent: newCoupon.discount_percent,
          max_uses: newCoupon.max_uses,
          valid_days: couponFormValidDays,
        }),
      }).catch(() => {});
    } catch (e) {}

    setCoupons([newCoupon, ...coupons]);
    setAuditLogs((prev) => [
      {
        id: 'log_' + Date.now(),
        actor: 'founder_admin (hmmhasan8@gmail.com)',
        action: 'coupons.created',
        entity: cleanCode,
        timestamp: 'Just now',
        details: `Created new promo coupon '${cleanCode}' with ${newCoupon.discount_percent}% discount (Max uses: ${newCoupon.max_uses})`,
      },
      ...prev,
    ]);

    setShowCreateCouponModal(false);
    setCouponFormCode('');
    setCouponFormDiscount(50);
    setCouponFormMaxUses(500);
  };

  const toggleCouponActive = (couponId: string) => {
    setCoupons((prev) =>
      prev.map((c) => {
        if (c.id === couponId) {
          const next = !c.is_active;
          try {
            fetch(`/founder/coupons/${couponId}`, {
              method: 'PUT',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ is_active: next }),
            }).catch(() => {});
          } catch (e) {}

          setAuditLogs((a) => [
            {
              id: 'log_' + Date.now(),
              actor: 'founder_admin (hmmhasan8@gmail.com)',
              action: 'coupons.toggle_active',
              entity: c.code,
              timestamp: 'Just now',
              details: `Coupon '${c.code}' status toggled to ${next ? 'ACTIVE' : 'INACTIVE'}`,
            },
            ...a,
          ]);

          return { ...c, is_active: next };
        }
        return c;
      })
    );
  };

  const handleDeleteCoupon = (couponId: string) => {
    const c = coupons.find((x) => x.id === couponId);
    setCoupons((prev) => prev.filter((x) => x.id !== couponId));
    if (c) {
      setAuditLogs((a) => [
        {
          id: 'log_' + Date.now(),
          actor: 'founder_admin (hmmhasan8@gmail.com)',
          action: 'coupons.deleted',
          entity: c.code,
          timestamp: 'Just now',
          details: `Deleted promo coupon '${c.code}'`,
        },
        ...a,
      ]);
    }
  };

  const handleSaveColumns = (updated: GenericColumnDefinition[]) => {
    setColumnsState((prev) => ({
      ...prev,
      [selectedEntityKey]: updated,
    }));

    if (onSaveColumnsGlobal) {
      onSaveColumnsGlobal(selectedEntityKey, updated);
    }

    setAuditLogs((prev) => [
      {
        id: 'log_' + Date.now(),
        actor: 'founder_admin (hmmhasan8@gmail.com)',
        action: 'entities.columns_renamed',
        entity: selectedEntityKey,
        timestamp: 'Just now',
        details: `Saved 15-column configuration for '${selectedEntityKey}'. Active count: ${
          updated.filter((c) => c.is_active).length
        }`,
      },
      ...prev,
    ]);
  };

  const current15Columns = columnsState[selectedEntityKey] || DEFAULT_ENTITY_COLUMNS[selectedEntityKey] || [];

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 flex flex-col font-sans">
      {/* Top Header */}
      <header className="bg-slate-900 text-white px-6 py-4 flex items-center justify-between border-b border-slate-800 shadow-md">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-indigo-600 text-white rounded-lg">
            <ShieldCheck className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-base tracking-wide">FOUNDER CONTROL SYSTEM</span>
              <span className="text-[10px] bg-indigo-500/20 text-indigo-300 border border-indigo-500/40 px-2 py-0.5 rounded-full font-bold">
                ROOT CONTROL PANEL
              </span>
            </div>
            <span className="text-xs text-slate-400">
              Create & Rename Modules • Create & Rename Tables • 15 Generic Columns
            </span>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="text-right hidden sm:block">
            <div className="text-xs font-bold text-slate-200">HMM Hasan (Founder)</div>
            <div className="text-[10px] text-emerald-400 font-mono">Role: Root Administrator</div>
          </div>
          <button
            onClick={() => setIsAuthenticated(!isAuthenticated)}
            className="p-2 hover:bg-slate-800 rounded-lg text-slate-400 hover:text-white transition"
            title="Lock session"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </header>

      {/* Tabs */}
      <div className="bg-white border-b border-slate-200 px-6 flex overflow-x-auto gap-2">
        {[
          { id: 'entities', label: 'Entities (Tables Manager)', icon: Table, count: entities.length, highlight: true },
          { id: 'modules', label: 'Modules Manager', icon: Layers, count: modules.length },
          { id: 'rename_columns', label: '15 Columns Renaming Desk', icon: Sliders },
          { id: 'coupons', label: 'Coupon Manager', icon: Tag, count: coupons.length },
          { id: 'audit', label: 'Audit Trail', icon: FileText, count: auditLogs.length },
        ].map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`py-3.5 px-4 text-xs font-bold flex items-center gap-2 border-b-2 transition whitespace-nowrap ${
                isActive
                  ? 'border-indigo-600 text-indigo-600 bg-indigo-50/50'
                  : 'border-transparent text-slate-600 hover:text-slate-900 hover:bg-slate-50'
              }`}
            >
              <Icon className="w-4 h-4" />
              <span>{tab.label}</span>
              {tab.count !== undefined && (
                <span
                  className={`text-[10px] px-1.5 py-0.5 rounded-full ${
                    isActive ? 'bg-indigo-600 text-white' : 'bg-slate-200 text-slate-700'
                  }`}
                >
                  {tab.count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* MAIN CONTENT AREA */}
      <main className="p-6 flex-1 max-w-7xl mx-auto w-full space-y-6">
        {/* =================================================================== */}
        {/* TAB 1: ENTITIES (TABLES MANAGER - CREATE, RENAME, ACTIVE/INACTIVE)  */}
        {/* =================================================================== */}
        {activeTab === 'entities' && (
          <div className="space-y-6">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <h2 className="text-xl font-bold text-slate-900">
                  Custom Tables (Entities) Manager
                </h2>
                <p className="text-xs text-slate-500">
                  Create new tables, rename existing tables, or toggle Active/Inactive. Each table has 15 generic columns.
                </p>
              </div>

              <button
                onClick={() => {
                  setEntityFormKey('');
                  setEntityFormNameEn('');
                  setEntityFormNameBn('');
                  setEntityFormUnlockFee(0.5);
                  setEntityFormValidity(7);
                  setShowCreateEntityModal(true);
                }}
                className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold flex items-center gap-2 shadow-sm transition"
              >
                <Plus className="w-4 h-4" />
                <span>Create New Table (Entity)</span>
              </button>
            </div>

            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 uppercase font-bold tracking-wider">
                  <tr>
                    <th className="p-4 w-16 text-center">Status</th>
                    <th className="p-4">Table Key</th>
                    <th className="p-4">Parent Module</th>
                    <th className="p-4">Name (English / বাংলা)</th>
                    <th className="p-4">Unlock Fee</th>
                    <th className="p-4">Validity</th>
                    <th className="p-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {entities.map((e) => {
                    const entCols = columnsState[e.entity_key] || DEFAULT_ENTITY_COLUMNS[e.entity_key] || [];
                    const activeColsCount = entCols.filter((c) => c.is_active).length;

                    return (
                      <tr key={e.id} className={`transition ${e.is_active ? 'hover:bg-slate-50' : 'bg-slate-50/60 opacity-60'}`}>
                        {/* ACTIVE / INACTIVE TOGGLE */}
                        <td className="p-4 text-center">
                          <button
                            onClick={() => toggleEntityActive(e.id)}
                            className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${
                              e.is_active ? 'bg-emerald-600' : 'bg-slate-300'
                            }`}
                            title={e.is_active ? 'Active in app' : 'Inactive (Hidden in app)'}
                          >
                            <span
                              className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white transition-transform ${
                                e.is_active ? 'translate-x-4' : 'translate-x-1'
                              }`}
                            />
                          </button>
                        </td>

                        <td className="p-4 font-mono font-bold text-indigo-600">
                          {e.entity_key}
                        </td>

                        <td className="p-4 font-mono text-slate-500">
                          {e.module_key}
                        </td>

                        <td className="p-4 font-semibold text-slate-900">
                          {e.name.en} <span className="text-slate-400 font-normal">({e.name.bn})</span>
                        </td>

                        <td className="p-4">
                          <div className="flex items-center gap-1.5 bg-emerald-50/70 p-1.5 rounded-xl border border-emerald-200/80 w-fit">
                            <span className="text-emerald-700 font-bold">$</span>
                            <input
                              type="number"
                              step="0.05"
                              min="0.05"
                              max="100.00"
                              value={e.unlock_fee_usd}
                              onChange={(ev) => handleInlineFeeChange(e.id, parseFloat(ev.target.value))}
                              className="w-16 px-1.5 py-0.5 bg-white border border-emerald-300 rounded font-mono font-bold text-xs text-emerald-800 outline-none focus:ring-1 focus:ring-emerald-500"
                              title="সরাসরি সম্পাদনযোগ্য আনলক ফি (Inline Commission Editor)"
                            />
                            <span className="text-[11px] font-semibold text-emerald-800 whitespace-nowrap pr-1">
                              (≈ ৳{Math.round(e.unlock_fee_usd * 120)})
                            </span>
                          </div>
                        </td>

                        <td className="p-4 text-slate-600 font-medium">
                          {e.validity_days} Days
                        </td>

                        <td className="p-4 text-right">
                          <div className="flex items-center justify-end gap-2">
                            {/* RENAME / EDIT BUTTON */}
                            <button
                              onClick={() => {
                                setEditingEntity(e);
                                setEntityFormNameEn(e.name.en);
                                setEntityFormNameBn(e.name.bn);
                                setEntityFormUnlockFee(e.unlock_fee_usd);
                                setEntityFormValidity(e.validity_days);
                              }}
                              className="px-2.5 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-lg text-xs flex items-center gap-1 transition"
                              title="Rename Table / Change Fee"
                            >
                              <Edit3 className="w-3.5 h-3.5 text-slate-600" />
                              <span>Rename</span>
                            </button>

                            {/* MANAGE 15 FIELDS BUTTON */}
                            <button
                              onClick={() => {
                                setSelectedEntityKey(e.entity_key);
                                setActiveTab('rename_columns');
                              }}
                              className="px-3 py-1.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold rounded-lg text-xs flex items-center gap-1 transition"
                            >
                              <span>Manage 15 Fields ({activeColsCount}) →</span>
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* =================================================================== */}
        {/* TAB 2: MODULES MANAGER (CREATE, RENAME, ACTIVE/INACTIVE)            */}
        {/* =================================================================== */}
        {activeTab === 'modules' && (
          <div className="space-y-6">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <h2 className="text-xl font-bold text-slate-900">
                  Business Modules (Verticals) Manager
                </h2>
                <p className="text-xs text-slate-500">
                  Create new business verticals (e.g. <code>home_service</code>, <code>delivery</code>, <code>marketplace</code>) or toggle active status.
                </p>
              </div>

              <button
                onClick={() => {
                  setModuleFormKey('');
                  setModuleFormNameEn('');
                  setModuleFormNameBn('');
                  setModuleFormCountries(['*']);
                  setShowCreateModuleModal(true);
                }}
                className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold flex items-center gap-2 shadow-sm transition"
              >
                <Plus className="w-4 h-4" />
                <span>Create New Module</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {modules.map((m) => (
                <div
                  key={m.id}
                  className={`bg-white p-5 rounded-2xl border transition shadow-sm ${
                    m.is_active ? 'border-slate-200' : 'border-slate-200 opacity-60 bg-slate-50/50'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-base text-slate-900">{m.name.en}</span>
                        <span className="text-xs font-medium text-slate-500 font-bengali">({m.name.bn})</span>
                      </div>
                      <div className="text-xs font-mono text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded inline-block mt-1">
                        key: {m.module_key}
                      </div>
                    </div>

                    {/* ACTIVE / INACTIVE TOGGLE */}
                    <div className="flex items-center gap-2">
                      <span className={`text-[11px] font-bold ${m.is_active ? 'text-emerald-700' : 'text-slate-400'}`}>
                        {m.is_active ? 'Active' : 'Inactive'}
                      </span>
                      <button
                        onClick={() => toggleModuleActive(m.id)}
                        className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${
                          m.is_active ? 'bg-emerald-600' : 'bg-slate-300'
                        }`}
                      >
                        <span
                          className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white transition-transform ${
                            m.is_active ? 'translate-x-4' : 'translate-x-1'
                          }`}
                        />
                      </button>
                    </div>
                  </div>

                  <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
                    <span>Regions: {m.allowed_countries.join(', ')}</span>

                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => {
                          setEditingModule(m);
                          setModuleFormNameEn(m.name.en);
                          setModuleFormNameBn(m.name.bn);
                          setModuleFormCountries(m.allowed_countries);
                        }}
                        className="px-2.5 py-1 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg font-bold flex items-center gap-1 transition"
                      >
                        <Edit3 className="w-3 h-3" />
                        <span>Rename</span>
                      </button>

                      <button
                        onClick={() => {
                          setActiveTab('entities');
                        }}
                        className="text-indigo-600 hover:underline font-bold"
                      >
                        View Tables →
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* =================================================================== */}
        {/* TAB 3: 15 GENERIC COLUMNS RENAMING DESK                             */}
        {/* =================================================================== */}
        {activeTab === 'rename_columns' && (
          <div className="space-y-6">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <h2 className="text-xl font-bold text-slate-900">
                  Manage 15 Columns for Table/Entity
                </h2>
                <p className="text-xs text-slate-500">
                  Select a table below. You will see 15 rows (<code>custom_col_1</code> to <code>custom_col_15</code>). Rename labels, pick data types, and toggle <strong>Active</strong>.
                </p>
              </div>

              {/* Entity Selector Pills */}
              <div className="flex items-center gap-2 bg-slate-200/70 p-1 rounded-xl overflow-x-auto max-w-full">
                {entities.map((ent) => (
                  <button
                    key={ent.entity_key}
                    onClick={() => setSelectedEntityKey(ent.entity_key)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 whitespace-nowrap ${
                      selectedEntityKey === ent.entity_key
                        ? 'bg-indigo-600 text-white shadow-xs'
                        : 'text-slate-700 hover:bg-white/50'
                    }`}
                  >
                    <span>{ent.name.bn}</span>
                    <span className="text-[10px] font-mono opacity-80">({ent.entity_key})</span>
                  </button>
                ))}
              </div>
            </div>

            <FieldBuilder
              entityKey={selectedEntityKey}
              entityName={entities.find((e) => e.entity_key === selectedEntityKey)?.name.bn || selectedEntityKey}
              initialColumns={current15Columns}
              onSaveColumns={handleSaveColumns}
            />
          </div>
        )}

        {/* =================================================================== */}
        {/* TAB 4: COUPON MANAGER (MODULE 3: MARKETING & DISCOUNTS)             */}
        {/* =================================================================== */}
        {activeTab === 'coupons' && (
          <div className="space-y-6">
            <div className="flex flex-wrap items-center justify-between gap-4">
              <div>
                <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2">
                  <Tag className="w-5 h-5 text-indigo-600" />
                  <span>কুপন ও ডিসকাউন্ট ম্যানেজার (Coupon Manager)</span>
                </h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  সার্ভিস আনলক ও রিকোয়েস্ট অ্যাকসেপ্ট ফি-তে ছাড় দেওয়ার জন্য প্রমো কোড তৈরি ও নিয়ন্ত্রণ করুন।
                </p>
              </div>

              <button
                onClick={() => {
                  setCouponFormCode('');
                  setCouponFormDiscount(50);
                  setCouponFormMaxUses(500);
                  setCouponFormValidDays(30);
                  setShowCreateCouponModal(true);
                }}
                className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold flex items-center gap-2 shadow-sm transition"
              >
                <Plus className="w-4 h-4" />
                <span>নতুন কুপন তৈরি করুন</span>
              </button>
            </div>

            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 uppercase font-bold tracking-wider">
                  <tr>
                    <th className="p-4 w-16 text-center">Status</th>
                    <th className="p-4">Coupon Code</th>
                    <th className="p-4">Discount</th>
                    <th className="p-4">Usage (Used / Max)</th>
                    <th className="p-4">Valid Until</th>
                    <th className="p-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {coupons.map((c) => (
                    <tr key={c.id} className={`transition ${c.is_active ? 'hover:bg-slate-50' : 'bg-slate-50/60 opacity-60'}`}>
                      <td className="p-4 text-center">
                        <button
                          onClick={() => toggleCouponActive(c.id)}
                          className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${
                            c.is_active ? 'bg-emerald-600' : 'bg-slate-300'
                          }`}
                          title={c.is_active ? 'Active' : 'Inactive'}
                        >
                          <span
                            className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white transition-transform ${
                              c.is_active ? 'translate-x-4' : 'translate-x-1'
                            }`}
                          />
                        </button>
                      </td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 bg-indigo-50 border border-indigo-200 text-indigo-700 font-mono font-extrabold rounded-lg text-xs">
                          {c.code}
                        </span>
                      </td>
                      <td className="p-4 font-bold text-emerald-600">
                        {c.discount_percent}% ছাড়
                      </td>
                      <td className="p-4 font-mono text-slate-700">
                        <span className="font-bold text-slate-900">{c.used_count}</span>
                        <span className="text-slate-400"> / {c.max_uses} বার</span>
                      </td>
                      <td className="p-4 text-slate-600 font-medium font-mono">
                        {c.valid_until}
                      </td>
                      <td className="p-4 text-right">
                        <button
                          onClick={() => handleDeleteCoupon(c.id)}
                          className="p-1.5 hover:bg-rose-50 text-slate-400 hover:text-rose-600 rounded-lg transition"
                          title="কুপন মুছুন"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="p-4 bg-indigo-50/60 border border-indigo-200 rounded-2xl flex items-start gap-3 text-xs text-indigo-950">
              <Tag className="w-4 h-4 text-indigo-600 flex-shrink-0 mt-0.5" />
              <div>
                <span className="font-bold">সক্রিয় কুপন প্রয়োগ ব্যবস্থা:</span>
                <p className="text-indigo-800 text-[11px] mt-0.5 leading-relaxed">
                  গ্রাহক বা প্রোভাইডার আনলক পপআপ বা আবেদন গ্রহণ পৃষ্ঠায় কুপন কোড (যেমন: <code>EID50</code>) ইনপুট দিলে স্বয়ংক্রিয়ভাবে ডিসকাউন্ট প্রযোজ্য হবে।
                </p>
              </div>
            </div>
          </div>
        )}

        {/* =================================================================== */}
        {/* TAB 5: AUDIT TRAIL                                                  */}
        {/* =================================================================== */}
        {activeTab === 'audit' && (
          <div className="space-y-4">
            <h2 className="text-xl font-bold text-slate-900">Immutable Audit Trail</h2>
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 uppercase font-bold tracking-wider">
                  <tr>
                    <th className="p-4">Timestamp</th>
                    <th className="p-4">Actor</th>
                    <th className="p-4">Action</th>
                    <th className="p-4">Target</th>
                    <th className="p-4">Details</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {auditLogs.map((log) => (
                    <tr key={log.id} className="hover:bg-slate-50 transition">
                      <td className="p-4 font-mono text-slate-500">{log.timestamp}</td>
                      <td className="p-4 font-semibold text-slate-800">{log.actor}</td>
                      <td className="p-4 font-mono text-indigo-600 font-bold">{log.action}</td>
                      <td className="p-4 font-mono text-slate-700">{log.entity}</td>
                      <td className="p-4 text-slate-600">{log.details}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </main>

      {/* =================================================================== */}
      {/* MODAL 1: CREATE NEW ENTITY (TABLE)                                  */}
      {/* =================================================================== */}
      {showCreateEntityModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
              <Table className="w-5 h-5 text-indigo-600" />
              <h3 className="font-bold text-base text-slate-900">Create New Table (Entity)</h3>
            </div>

            <form onSubmit={handleCreateEntity} className="space-y-4 text-xs">
              <div>
                <label className="block font-bold text-slate-700 uppercase mb-1">Parent Module *</label>
                <select
                  value={entityFormModuleId}
                  onChange={(e) => setEntityFormModuleId(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none font-semibold text-xs"
                >
                  {modules.map((m) => (
                    <option key={m.id} value={m.id}>
                      {m.name.en} ({m.module_key})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block font-bold text-slate-700 uppercase mb-1">
                  Table Key (Database identifier) *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. ac_services, plumbers, flats"
                  value={entityFormKey}
                  onChange={(e) => setEntityFormKey(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none font-mono"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Table Name (EN) *</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. AC Repair"
                    value={entityFormNameEn}
                    onChange={(e) => setEntityFormNameEn(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Table Name (বাংলা) *</label>
                  <input
                    type="text"
                    placeholder="যেমন: এসি সার্ভিস"
                    value={entityFormNameBn}
                    onChange={(e) => setEntityFormNameBn(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none font-bengali"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Unlock Fee ($ USD)</label>
                  <input
                    type="number"
                    step="0.1"
                    value={entityFormUnlockFee}
                    onChange={(e) => setEntityFormUnlockFee(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Validity (Days)</label>
                  <input
                    type="number"
                    value={entityFormValidity}
                    onChange={(e) => setEntityFormValidity(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none"
                  />
                </div>
              </div>

              <div className="p-3 bg-indigo-50 border border-indigo-200 rounded-xl text-indigo-900 text-[11px] leading-relaxed">
                ✨ নতুন টেবিল তৈরি করলে স্বয়ংক্রিয়ভাবে ১৫টি জেনেরিক কলাম (<code>custom_col_1..15</code>) তৈরি হয়ে যাবে। আপনি পরবর্তীতে ইচ্ছামতো কলামগুলোর নাম ও লেবেল পরিবর্তন করতে পারবেন।
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowCreateEntityModal(false)}
                  className="flex-1 py-2.5 bg-slate-100 text-slate-700 font-bold rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-sm"
                >
                  Create Table (Entity)
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =================================================================== */}
      {/* MODAL 2: EDIT / RENAME EXISTING ENTITY (TABLE)                      */}
      {/* =================================================================== */}
      {editingEntity && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
              <Edit3 className="w-5 h-5 text-indigo-600" />
              <div>
                <h3 className="font-bold text-base text-slate-900">Rename Table: {editingEntity.entity_key}</h3>
                <span className="text-[11px] text-slate-400">Update table display titles and unlock fee</span>
              </div>
            </div>

            <form onSubmit={handleUpdateEntity} className="space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Table Name (EN) *</label>
                  <input
                    type="text"
                    required
                    value={entityFormNameEn}
                    onChange={(e) => setEntityFormNameEn(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Table Name (বাংলা) *</label>
                  <input
                    type="text"
                    value={entityFormNameBn}
                    onChange={(e) => setEntityFormNameBn(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none font-bengali"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Unlock Fee ($ USD)</label>
                  <input
                    type="number"
                    step="0.1"
                    value={entityFormUnlockFee}
                    onChange={(e) => setEntityFormUnlockFee(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Validity (Days)</label>
                  <input
                    type="number"
                    value={entityFormValidity}
                    onChange={(e) => setEntityFormValidity(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none"
                  />
                </div>
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setEditingEntity(null)}
                  className="flex-1 py-2.5 bg-slate-100 text-slate-700 font-bold rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-sm"
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =================================================================== */}
      {/* MODAL 3: CREATE NEW MODULE                                          */}
      {/* =================================================================== */}
      {showCreateModuleModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
              <Layers className="w-5 h-5 text-indigo-600" />
              <h3 className="font-bold text-base text-slate-900">Create Business Module</h3>
            </div>

            <form onSubmit={handleCreateModule} className="space-y-4 text-xs">
              <div>
                <label className="block font-bold text-slate-700 uppercase mb-1">
                  Module Key (e.g. home_service, marketplace) *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. real_estate"
                  value={moduleFormKey}
                  onChange={(e) => setModuleFormKey(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none font-mono"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Module Name (EN) *</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Real Estate"
                    value={moduleFormNameEn}
                    onChange={(e) => setModuleFormNameEn(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Module Name (বাংলা) *</label>
                  <input
                    type="text"
                    placeholder="যেমন: রিয়েল এস্টেট"
                    value={moduleFormNameBn}
                    onChange={(e) => setModuleFormNameBn(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none font-bengali"
                  />
                </div>
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowCreateModuleModal(false)}
                  className="flex-1 py-2.5 bg-slate-100 text-slate-700 font-bold rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-sm"
                >
                  Create Module
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =================================================================== */}
      {/* MODAL 4: EDIT / RENAME EXISTING MODULE                              */}
      {/* =================================================================== */}
      {editingModule && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
              <Edit3 className="w-5 h-5 text-indigo-600" />
              <div>
                <h3 className="font-bold text-base text-slate-900">Rename Module: {editingModule.module_key}</h3>
                <span className="text-[11px] text-slate-400">Change module display names</span>
              </div>
            </div>

            <form onSubmit={handleUpdateModule} className="space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Module Name (EN) *</label>
                  <input
                    type="text"
                    required
                    value={moduleFormNameEn}
                    onChange={(e) => setModuleFormNameEn(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">Module Name (বাংলা) *</label>
                  <input
                    type="text"
                    value={moduleFormNameBn}
                    onChange={(e) => setModuleFormNameBn(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none font-bengali"
                  />
                </div>
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setEditingModule(null)}
                  className="flex-1 py-2.5 bg-slate-100 text-slate-700 font-bold rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-sm"
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =================================================================== */}
      {/* MODAL 5: CREATE NEW DISCOUNT COUPON (MODULE 3)                      */}
      {/* =================================================================== */}
      {showCreateCouponModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full shadow-2xl space-y-4">
            <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
              <Tag className="w-5 h-5 text-indigo-600" />
              <div>
                <h3 className="font-bold text-base text-slate-900">নতুন কুপন কোড তৈরি করুন</h3>
                <span className="text-[11px] text-slate-400">মার্কেটিং প্রমো ও আনলক ডিসকাউন্ট</span>
              </div>
            </div>

            <form onSubmit={handleCreateCoupon} className="space-y-4 text-xs">
              <div>
                <label className="block font-bold text-slate-700 uppercase mb-1">
                  কুপন কোড (যেমন: EID50, DHAKA20) *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. EID50"
                  value={couponFormCode}
                  onChange={(e) => setCouponFormCode(e.target.value.toUpperCase())}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none font-mono uppercase font-bold text-indigo-700 text-sm"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">
                    ডিসকাউন্ট শতকরা (%) *
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="100"
                    required
                    value={couponFormDiscount}
                    onChange={(e) => setCouponFormDiscount(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none font-bold"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-700 uppercase mb-1">
                    সর্বোচ্চ ব্যবহার (বার) *
                  </label>
                  <input
                    type="number"
                    min="1"
                    required
                    value={couponFormMaxUses}
                    onChange={(e) => setCouponFormMaxUses(Number(e.target.value))}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block font-bold text-slate-700 uppercase mb-1">
                  মেয়াদ (দিন) *
                </label>
                <input
                  type="number"
                  min="1"
                  required
                  value={couponFormValidDays}
                  onChange={(e) => setCouponFormValidDays(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-300 rounded-lg outline-none"
                />
              </div>

              <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-amber-900 text-[11px]">
                💡 প্রোভাইডার ও গ্রাহক উভয়ই আনলক করার সময় বা আবেদন গ্রহণের সময় এই কোড ব্যবহার করতে পারবে।
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowCreateCouponModal(false)}
                  className="flex-1 py-2.5 bg-slate-100 text-slate-700 font-bold rounded-xl"
                >
                  বাতিল
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-sm"
                >
                  কুপন তৈরি করুন
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
