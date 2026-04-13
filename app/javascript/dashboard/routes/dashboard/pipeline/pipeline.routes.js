import { frontendURL } from '../../../helper/URLHelper';
import PipelineView from './PipelineView.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';

const commonMeta = {
  featureFlag: FEATURE_FLAGS.PIPELINES,
  permissions: ['administrator', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/pipelines'),
    name: 'pipelines_dashboard',
    component: PipelineView,
    meta: commonMeta,
  },
  {
    path: frontendURL('accounts/:accountId/pipelines/:pipelineId'),
    name: 'pipeline_board',
    component: PipelineView,
    meta: commonMeta,
    props: route => ({
      pipelineId: route.params.pipelineId,
    }),
  },
];
