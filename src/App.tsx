import React, { useState } from 'react';
import UserClientPanel from '../founder-panel/app/page';
import StaffModerationPage from '../founder-panel/app/staff/page';
import FounderControlPage, {
  DEFAULT_ENTITY_COLUMNS,
  EntityItem,
  ModuleItem,
} from '../founder-panel/app/founder/page';
import { GenericColumnDefinition } from '../founder-panel/components/FieldBuilder';
import { Smartphone, ShieldAlert, Sliders, Database } from 'lucide-react';

export default function App() {
  const [currentRoute, setCurrentRoute] = useState<'founder' | 'client' | 'staff'>('founder');

  // Shared 15 Columns state across Founder and Client panels
  const [entityColumnsState, setEntityColumnsState] = useState<Record<string, GenericColumnDefinition[]>>(
    DEFAULT_ENTITY_COLUMNS
  );

  // Shared Modules List
  const [modulesList, setModulesList] = useState<ModuleItem[]>([
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
  ]);

  // Shared Entities List (Tables)
  const [entitiesList, setEntitiesList] = useState<EntityItem[]>([
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
  ]);

  const handleGlobalSaveColumns = (entityKey: string, columns: GenericColumnDefinition[]) => {
    setEntityColumnsState((prev) => ({
      ...prev,
      [entityKey]: columns,
    }));
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-950 text-slate-100 font-sans">
      {/* GLOBAL 3-PANEL PREVIEW SWITCHER BAR */}
      <div className="bg-slate-900 border-b border-slate-800 px-4 py-2.5 flex flex-wrap items-center justify-between gap-3 shadow-lg z-50 sticky top-0">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 bg-indigo-600 rounded-lg flex items-center justify-center font-extrabold text-sm text-white shadow-xs">
            15
          </div>
          <div>
            <span className="font-extrabold text-xs tracking-wider text-white">
              SERVICE PLATFORM <span className="text-indigo-400 font-mono">ROOT CONTROL SYSTEM</span>
            </span>
          </div>
        </div>

        {/* Panel Switcher Tabs */}
        <div className="flex items-center bg-slate-950 p-1 rounded-xl border border-slate-800 text-xs">
          <button
            onClick={() => setCurrentRoute('founder')}
            className={`px-3 py-1.5 rounded-lg font-bold transition flex items-center gap-1.5 ${
              currentRoute === 'founder'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Sliders className="w-3.5 h-3.5" />
            <span>Panel 1: Founder (Tables & Modules)</span>
          </button>

          <button
            onClick={() => setCurrentRoute('client')}
            className={`px-3 py-1.5 rounded-lg font-bold transition flex items-center gap-1.5 ${
              currentRoute === 'client'
                ? 'bg-blue-600 text-white shadow-sm'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Smartphone className="w-3.5 h-3.5" />
            <span>Panel 3: User App (Dynamic Tabs)</span>
          </button>

          <button
            onClick={() => setCurrentRoute('staff')}
            className={`px-3 py-1.5 rounded-lg font-bold transition flex items-center gap-1.5 ${
              currentRoute === 'staff'
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <ShieldAlert className="w-3.5 h-3.5" />
            <span>Panel 2: Staff (/staff)</span>
          </button>
        </div>

        <div className="hidden lg:flex items-center gap-2 text-[11px] text-slate-400">
          <Database className="w-3.5 h-3.5 text-emerald-400" />
          <span>Modules CRUD • Tables CRUD • 15 Generic Columns</span>
        </div>
      </div>

      {/* RENDER CURRENT PANEL WITH SHARED 15-COLUMN AND ENTITY STATE */}
      <div className="flex-1 bg-slate-100 text-slate-900">
        {currentRoute === 'founder' && (
          <FounderControlPage
            entityColumnsState={entityColumnsState}
            entitiesList={entitiesList}
            modulesList={modulesList}
            onSaveColumnsGlobal={handleGlobalSaveColumns}
            onUpdateEntitiesGlobal={setEntitiesList}
            onUpdateModulesGlobal={setModulesList}
          />
        )}
        {currentRoute === 'client' && (
          <UserClientPanel
            entityColumnsState={entityColumnsState}
            entitiesList={entitiesList}
          />
        )}
        {currentRoute === 'staff' && <StaffModerationPage />}
      </div>
    </div>
  );
}
